#!/usr/bin/env bash
# tasknotify.sh — rofi-based task manager with notifications
# Dependencies: rofi, notify-send, jq, xdg-open

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tasknotify"
TASKS_FILE="$DATA_DIR/tasks.json"
CONFIG_FILE="$DATA_DIR/config.json"
SOUND_DIR="$DATA_DIR/sounds"
LOG_FILE="$DATA_DIR/tasknotify.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$DATA_DIR" "$SOUND_DIR"

# ── Bootstrap empty tasks file ────────────────────────────────────────────────
[[ -f "$TASKS_FILE" ]] || echo '[]' >"$TASKS_FILE"

# ── Default config ────────────────────────────────────────────────────────────
[[ -f "$CONFIG_FILE" ]] || cat >"$CONFIG_FILE" <<'EOF'
{
  "notify_sound": "",
  "notify_icon": "",
  "rofi_theme": ""
}
EOF

# ── Helpers ───────────────────────────────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >>"$LOG_FILE"; }

read_cfg() { jq -r ".$1 // empty" "$CONFIG_FILE" 2>/dev/null; }

new_id() { echo "$(date +%s%N)_$$_$RANDOM"; }

play_sound() {
  local sound_file
  sound_file="$(read_cfg notify_sound)"
  [[ -z "$sound_file" ]] && return 0
  [[ -f "$sound_file" ]] || sound_file="$SOUND_DIR/$sound_file"
  [[ -f "$sound_file" ]] || return 0
  for player in paplay aplay mpv ffplay; do
    if command -v "$player" &>/dev/null; then
      "$player" "$sound_file" &>/dev/null &
      return 0
    fi
  done
}

send_notify() {
  local urgency="$1" summary="$2" body="$3"
  local icon
  icon="$(read_cfg notify_icon)"
  local args=(-u "$urgency" "$summary" "$body")
  [[ -n "$icon" ]] && args+=(-i "$icon")
  notify-send "${args[@]}"
  play_sound
  log "NOTIFY [$urgency] $summary — $body"
}

to_epoch() {
  local dt="${1//T/ }"
  [[ "$dt" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && dt="$dt 23:59"
  date -d "$dt" +%s 2>/dev/null || echo 0
}

fmt_epoch() {
  date -d "@$1" '+%b %d • %H:%M'
}

# ── Task CRUD ─────────────────────────────────────────────────────────────────
tasks_write() {
  local tmp
  tmp=$(mktemp)
  jq '.' >"$tmp" && mv "$tmp" "$TASKS_FILE"
}

task_add() {
  local name="$1" datetime="$2" link="${3:-}"
  local id epoch
  id="$(new_id)"
  epoch="$(to_epoch "$datetime")"
  jq --arg id "$id" \
    --arg name "$name" \
    --argjson epoch "$epoch" \
    --arg datetime "$datetime" \
    --arg link "$link" \
    '. += [{
           "id":       $id,
           "name":     $name,
           "datetime": $datetime,
           "epoch":    $epoch,
           "link":     $link,
           "done":     false,
           "created":  now | floor
       }]' "$TASKS_FILE" | tasks_write
  log "ADD [$id] $name @ $datetime"
}

task_complete() {
  local id="$1"
  jq --arg id "$id" 'map(select(.id != $id))' "$TASKS_FILE" | tasks_write
  log "COMPLETE [$id]"
}

tasks_sorted() {
  jq -c 'sort_by(.epoch) | sort_by(.done)' "$TASKS_FILE"
}

# ── Rofi helpers ──────────────────────────────────────────────────────────────
rofi_run() {
  local prompt="$1"
  shift
  local theme
  theme="$(read_cfg rofi_theme)"
  local args=(-dmenu -p "$prompt" -i "$@")
  [[ -n "$theme" ]] && args+=(-theme "$theme")
  rofi "${args[@]}"
}

rofi_input() {
  local prompt="$1"
  local prefill="${2:-}"
  local theme
  theme="$(read_cfg rofi_theme)"
  local args=(-dmenu -p "$prompt" -filter "$prefill" -l 0)
  [[ -n "$theme" ]] && args+=(-theme "$theme")
  rofi "${args[@]}"
}

# Like rofi_run but shows a visible list — used when items must be seen
rofi_input_list() {
  local prompt="$1"
  local theme
  theme="$(read_cfg rofi_theme)"
  local args=(-dmenu -p "$prompt" -i)
  [[ -n "$theme" ]] && args+=(-theme "$theme")
  rofi "${args[@]}"
}

# ── Add task wizard ───────────────────────────────────────────────────────────
ui_add_task() {
  local name
  name=$(rofi_input "Task name") || return 1
  [[ -z "$name" ]] && return 1

  local current_year
  current_year=$(date +%Y)

  local month
  month=$(printf "%s\n" \
    "1  Jan" "2  Feb" "3  Mar" "4  Apr" \
    "5  May" "6  Jun" "7  Jul" "8  Aug" \
    "9  Sep" "10 Oct" "11 Nov" "12 Dec" |
    rofi_run "Month" -format 's') || return 1
  month=$(echo "$month" | awk '{print $1}')
  [[ -z "$month" ]] && return 1

  local days_in_month
  days_in_month=$(cal "$month" "$current_year" | awk 'NF {DAYS = $NF}; END {print DAYS}')

  local day
  day=$({
    for d in $(seq 1 "$days_in_month"); do
      printf "%d  %s\n" "$d" "$(date -d "$current_year-$month-$d" '+%a')"
    done
  } | rofi_run "Day" -format 's') || return 1
  day=$(echo "$day" | awk '{print $1}')

  local hour
  hour=$(seq 0 23 | xargs -I{} printf "%02d\n" {} | rofi_run "Hour" -format 's') || return 1

  local minute
  minute=$(printf "00\n10\n20\n30\n40\n50\n" | rofi_run "Minute" -format 's') || return 1

  local dt
  printf -v dt "%04d-%02d-%02d %02d:%02d" \
    "$current_year" "$month" "$day" "$hour" "$minute"

  local epoch
  epoch="$(to_epoch "$dt")"
  if [[ "$epoch" -eq 0 ]]; then
    send_notify normal "tasknotify" "Invalid date"
    return 1
  fi

  local link
  link=$(rofi_input "Link (optional, blank to skip)") || link=""

  task_add "$name" "$dt" "$link"
  send_notify low "Task added" "$name  •  $(fmt_epoch "$epoch")"
}

# ── Shared: build display lines + ids arrays ──────────────────────────────────
# Caller must declare local arrays and pass their names as $1 and $2
_build_task_lines() {
  local lines_var="$1"
  local ids_var="$2"

  local now
  now=$(date +%s)

  while IFS= read -r task; do
    local id name epoch link done_flag
    id=$(echo "$task" | jq -r '.id')
    name=$(echo "$task" | jq -r '.name')
    epoch=$(echo "$task" | jq -r '.epoch')
    link=$(echo "$task" | jq -r '.link // ""')
    done_flag=$(echo "$task" | jq -r '.done')

    [[ "$done_flag" == "true" ]] && continue

    local dt_str
    dt_str="$(fmt_epoch "$epoch")"

    local delta=""
    if [[ "$epoch" -gt 0 ]]; then
      local diff=$((epoch - now))
      if [[ $diff -lt 0 ]]; then
        delta=" ⚠ overdue"
      elif [[ $diff -lt 3600 ]]; then
        delta=" ⏰ <1h"
      elif [[ $diff -lt 86400 ]]; then
        delta=" ⏳ today"
      elif [[ $diff -lt 172800 ]]; then
        delta=" 📅 tomorrow"
      fi
    fi

    local link_sym=""
    [[ -n "$link" ]] && link_sym=" 🔗"

    eval "${lines_var}+=(\"[ ]  \$name  •  \$dt_str\$delta\$link_sym\")"
    eval "${ids_var}+=(\"$id\")"
  done < <(tasks_sorted | jq -c '.[]')
}

# ── Main task list / action menu ──────────────────────────────────────────────
ui_task_list() {
  local lines=() ids=()
  _build_task_lines lines ids

  [[ ${#lines[@]} -eq 0 ]] && lines=("(no tasks)") && ids=("")

  lines+=("── Add new task ──")
  ids+=("__add__")

  local chosen_idx
  chosen_idx=$(printf '%s\n' "${lines[@]}" |
    rofi_run "Tasks" -format 'i' -no-custom) || return 0

  local chosen_id="${ids[$chosen_idx]:-}"

  if [[ "$chosen_id" == "__add__" ]]; then
    ui_add_task
    return 0
  fi
  [[ -z "$chosen_id" ]] && return 0

  local task_json task_name task_link
  task_json=$(jq -c --arg id "$chosen_id" '.[] | select(.id == $id)' "$TASKS_FILE")
  task_name=$(echo "$task_json" | jq -r '.name')
  task_link=$(echo "$task_json" | jq -r '.link // ""')

  local actions=("✓  Mark complete (remove)" "✎  Edit task")
  [[ -n "$task_link" ]] && actions+=("🔗  Open link")
  actions+=("✕  Cancel")

  local action
  action=$(printf '%s\n' "${actions[@]}" |
    rofi_run "$task_name" -no-custom) || return 0

  case "$action" in
  "✓"*)
    task_complete "$chosen_id"
    send_notify low "Task done" "$task_name"
    ;;
  "✎"*) _do_edit_task "$chosen_id" ;;
  "🔗"*) xdg-open "$task_link" &>/dev/null & ;;
  esac
}

# ── Edit picker (standalone: tasknotify.sh edit) ──────────────────────────────
ui_edit_picker() {
  local lines=() ids=()
  _build_task_lines lines ids

  if [[ ${#lines[@]} -eq 0 ]]; then
    send_notify low "tasknotify" "No tasks to edit"
    return 0
  fi

  local chosen_idx
  chosen_idx=$(printf '%s\n' "${lines[@]}" |
    rofi_run "Edit which task?" -format 'i' -no-custom) || return 0

  local chosen_id="${ids[$chosen_idx]:-}"
  [[ -z "$chosen_id" ]] && return 0

  _do_edit_task "$chosen_id"
}

# ── Edit form (shared by list submenu + edit picker) ─────────────────────────
_do_edit_task() {
  local id="$1"
  local task_json
  task_json=$(jq -c --arg id "$id" '.[] | select(.id == $id)' "$TASKS_FILE")

  local cur_name cur_link cur_epoch
  cur_name=$(echo "$task_json" | jq -r '.name')
  cur_link=$(echo "$task_json" | jq -r '.link // ""')
  cur_epoch=$(echo "$task_json" | jq -r '.epoch')

  # Parse current date parts for pre-selection
  local cur_year cur_month cur_day cur_hour cur_minute
  cur_year=$(date -d "@$cur_epoch" '+%Y')
  cur_month=$(date -d "@$cur_epoch" '+%-m')
  cur_day=$(date -d "@$cur_epoch" '+%-d')
  cur_hour=$(date -d "@$cur_epoch" '+%H')
  cur_minute=$(date -d "@$cur_epoch" '+%M')
  cur_minute=$(((10#$cur_minute / 10) * 10)) # round to nearest 10

  # ── Name: current value shown first, type to replace ─────────────────────
  local name
  name=$(printf "%s\n" "* keep: $cur_name" "$cur_name" |
    rofi_input_list "Name") || return 1
  [[ "$name" == "* keep:"* || -z "$name" ]] && name="$cur_name"

  # ── Month: current month first, then the rest ────────────────────────────
  local all_months=("1  Jan" "2  Feb" "3  Mar" "4  Apr" "5  May" "6  Jun"
    "7  Jul" "8  Aug" "9  Sep" "10 Oct" "11 Nov" "12 Dec")
  local cur_month_line="${all_months[$((cur_month - 1))]}"
  local other_months=()
  for m in "${all_months[@]}"; do
    [[ "$m" == "$cur_month_line" ]] && continue
    other_months+=("$m")
  done

  local month_pick
  month_pick=$(printf "%s\n" "* keep: $cur_month_line" "$cur_month_line" "${other_months[@]}" |
    rofi_input_list "Month") || return 1
  local month
  if [[ "$month_pick" == "* keep:"* || -z "$month_pick" ]]; then
    month="$cur_month"
  else
    month=$(echo "$month_pick" | awk '{print $1}')
  fi

  # ── Day: current day first ───────────────────────────────────────────────
  local days_in_month
  days_in_month=$(cal "$month" "$cur_year" | awk 'NF {DAYS = $NF}; END {print DAYS}')

  local day_pick
  day_pick=$({
    printf "* keep: %d  %s\n" "$cur_day" "$(date -d "$cur_year-$month-$cur_day" '+%a')"
    for d in $(seq 1 "$days_in_month"); do
      printf "%d  %s\n" "$d" "$(date -d "$cur_year-$month-$d" '+%a')"
    done
  } | rofi_input_list "Day") || return 1
  local day
  [[ "$day_pick" == "* keep:"* || -z "$day_pick" ]] && day="$cur_day" || day=$(echo "$day_pick" | awk '{print $1}')
  # ── Hour: current hour first ─────────────────────────────────────────────
  local hour_pick
  hour_pick=$({
    echo "* keep: $cur_hour"
    echo "$cur_hour"
    seq 0 23 | xargs -I{} printf "%02d\n" {} | grep -v "^${cur_hour}$"
  } | rofi_input_list "Hour") || return 1
  local hour
  [[ "$hour_pick" == "* keep:"* || -z "$hour_pick" ]] && hour="$cur_hour" || hour="$hour_pick"

  # ── Minute: current minute first ─────────────────────────────────────────
  local cur_min_fmt
  printf -v cur_min_fmt "%02d" "$cur_minute"
  local minute_pick
  minute_pick=$({
    echo "* keep: $cur_min_fmt"
    echo "$cur_min_fmt"
    printf "00\n10\n20\n30\n40\n50\n" | grep -v "^${cur_min_fmt}$"
  } | rofi_input_list "Minute") || return 1
  local minute
  [[ "$minute_pick" == "* keep:"* || -z "$minute_pick" ]] && minute="$cur_min_fmt" || minute="$minute_pick"

  # ── Link: current value shown first ──────────────────────────────────────
  local link
  if [[ -n "$cur_link" ]]; then
    link=$(printf "%s\n" "* keep: $cur_link" "$cur_link" |
      rofi_input_list "Link") || link="$cur_link"
    [[ "$link" == "* keep:"* || -z "$link" ]] && link="$cur_link"
  else
    link=$(rofi_input "Link (optional)") || link=""
  fi

  # ── Build and validate datetime ───────────────────────────────────────────
  local dt
  printf -v dt "%04d-%02d-%02d %02d:%02d" \
    "$cur_year" "$month" "$day" "$hour" "$minute"

  local epoch
  epoch="$(to_epoch "$dt")"
  if [[ "$epoch" -eq 0 ]]; then
    send_notify normal "tasknotify" "Invalid date — task unchanged"
    return 1
  fi

  jq --arg id "$id" \
    --arg name "$name" \
    --arg dt "$dt" \
    --argjson epoch "$epoch" \
    --arg link "$link" \
    'map(if .id == $id then
           .name = $name | .datetime = $dt | .epoch = $epoch | .link = $link
        else . end)' "$TASKS_FILE" | tasks_write

  log "EDIT [$id] -> $name @ $dt"
  send_notify low "Task updated" "$name  •  $(fmt_epoch "$epoch")"
}

# ── Notification checker (called by systemd timer) ────────────────────────────
run_checker() {
  # Ensure DBUS is reachable from the systemd --user context.
  # The canonical socket path works even when the service starts before
  # graphical-session.target is fully active.
  local uid
  uid=$(id -u)
  local dbus_path="/run/user/${uid}/bus"
  if [[ -S "$dbus_path" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=${dbus_path}"
  fi

  # If DISPLAY is still unset (e.g. standalone WM without a display manager),
  # try to discover an active X display from /tmp/.X11-unix/.
  if [[ -z "${DISPLAY:-}" ]]; then
    local disp
    disp=$(ls /tmp/.X11-unix/X* 2>/dev/null | head -1 | sed 's|/tmp/.X11-unix/X|:|')
    [[ -n "$disp" ]] && export DISPLAY="$disp"
  fi

  local now
  now=$(date +%s)
  local day=$((60 * 60 * 24))

  while IFS= read -r task; do
    local id name epoch done_flag link
    id=$(echo "$task" | jq -r '.id')
    name=$(echo "$task" | jq -r '.name')
    epoch=$(echo "$task" | jq -r '.epoch')
    done_flag=$(echo "$task" | jq -r '.done')
    link=$(echo "$task" | jq -r '.link // ""')

    [[ "$done_flag" == "true" ]] && continue
    [[ "$epoch" -eq 0 ]] && continue

    local diff=$((epoch - now))
    local dt_str
    dt_str="$(fmt_epoch "$epoch")"

    local fired_key_base="$DATA_DIR/.notified_${id}"
    local body="$dt_str"
    if [[ -n "$link" ]]; then
      short_link=$(echo "$link" | sed 's|https\?://||;s|www\.||;s|/.*||')
      body="$body  •  $short_link"
    fi
    # 1) Day before  → 24h..25h window
    if [[ $diff -ge $((day)) && $diff -lt $((day + 3600)) ]]; then
      local key="${fired_key_base}_daybefore"
      if [[ ! -f "$key" ]]; then
        send_notify normal "Tomorrow: $name" "$body"
        touch "$key"
      fi
    fi

    # 2) Day of  → same calendar day, before deadline
    local day_start
    day_start=$(date -d "@$epoch" '+%Y-%m-%d 00:00' | xargs -I{} date -d {} +%s)
    local day_end=$((day_start + day))
    if [[ $now -ge $day_start && $now -lt $day_end && $diff -gt 0 ]]; then
      local key="${fired_key_base}_dayon"
      if [[ ! -f "$key" ]]; then
        send_notify normal "Today: $name" "$body"
        touch "$key"
      fi
    fi

    # 3) 1 hour before  → 1h..1h+5min window
    if [[ $diff -ge 3600 && $diff -lt 3900 ]]; then
      local key="${fired_key_base}_1h"
      if [[ ! -f "$key" ]]; then
        send_notify critical "1 hour: $name" "$body"
        touch "$key"
      fi
    fi

    # 4) Deadline  → overdue by 0..10min
    if [[ $diff -le 0 && $diff -ge -600 ]]; then
      local key="${fired_key_base}_deadline"
      if [[ ! -f "$key" ]]; then
        send_notify critical "DEADLINE: $name" "$body"
        touch "$key"
      fi
    fi

  done < <(tasks_sorted | jq -c '.[]')
}

# ── Entrypoint ────────────────────────────────────────────────────────────────
case "${1:-ui}" in
ui) ui_task_list ;;
add) ui_add_task ;;
edit) ui_edit_picker ;;
check) run_checker ;;
*)
  echo "Usage: tasknotify.sh [ui|add|edit|check]"
  echo "  ui     — open rofi task manager (default)"
  echo "  add    — open add-task wizard directly"
  echo "  edit   — open edit picker directly"
  echo "  check  — run notification checker (used by systemd)"
  exit 1
  ;;
esac
