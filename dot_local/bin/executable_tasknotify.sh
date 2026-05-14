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

# Generate a simple unique ID (timestamp + random)
new_id() { echo "$(date +%s%N)_$$_$RANDOM"; }

# Play notification sound if configured
play_sound() {
  local sound_file
  sound_file="$(read_cfg notify_sound)"
  [[ -z "$sound_file" ]] && return 0
  [[ -f "$sound_file" ]] || sound_file="$SOUND_DIR/$sound_file"
  [[ -f "$sound_file" ]] || return 0
  # Try common players in order
  for player in paplay aplay mpv ffplay; do
    if command -v "$player" &>/dev/null; then
      "$player" "$sound_file" &>/dev/null &
      return 0
    fi
  done
}

# Send a desktop notification
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

# Parse ISO datetime to epoch
to_epoch() {
  # Accepts: "2025-12-31 18:00" or "2025-12-31T18:00" or "2025-12-31"
  local dt="${1//T/ }"
  [[ "$dt" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && dt="$dt 23:59"
  date -d "$dt" +%s 2>/dev/null || echo 0
}

# Pretty-print epoch → "Mon 31 Dec 18:00"
fmt_epoch() {
  date -d "@$1" '+%b %d • %H:%M'
}
# ── Task CRUD ─────────────────────────────────────────────────────────────────
tasks_read() { jq -c '.' "$TASKS_FILE"; }
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
  # Sort by epoch (ascending); done tasks last
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
  local theme
  theme="$(read_cfg rofi_theme)"
  local args=(-dmenu -p "$prompt" -filter "" -l 0)
  [[ -n "$theme" ]] && args+=(-theme "$theme")
  rofi "${args[@]}"
}

# ── Add task wizard ───────────────────────────────────────────────────────────
ui_add_task() {
  # ── Task name ─────────────────────────────────────────────
  local name
  name=$(echo "" | rofi_input "Task name") || return 1
  [[ -z "$name" ]] && return 1

  local current_year current_month current_day
  current_year=$(date +%Y)
  current_month=$(date +%-m)
  current_day=$(date +%-d)

  # ── Month picker ──────────────────────────────────────────
  local month
  month=$(printf "%s\n" \
    "1  Jan" "2  Feb" "3  Mar" "4  Apr" \
    "5  May" "6  Jun" "7  Jul" "8  Aug" \
    "9  Sep" "10 Oct" "11 Nov" "12 Dec" |
    rofi_run "Month" -format 's') || return 1

  month=$(echo "$month" | awk '{print $1}')
  [[ -z "$month" ]] && return 1

  # ── Day picker ────────────────────────────────────────────
  local days_in_month
  days_in_month=$(cal "$month" "$current_year" | awk 'NF {DAYS = $NF}; END {print DAYS}')

  local day_list=""
  for i in $(seq 1 "$days_in_month"); do
    day_list+="$i\n"
  done

  local day
  day=$(printf "$day_list" | rofi_run "Day" -format 's') || return 1
  [[ -z "$day" ]] && return 1

  # ── Hour picker ───────────────────────────────────────────
  local hour_list=""
  for i in $(seq 0 23); do
    printf -v hh "%02d" "$i"
    hour_list+="$hh\n"
  done

  local hour
  hour=$(printf "$hour_list" | rofi_run "Hour" -format 's') || return 1

  # ── Minute picker (10min steps) ──────────────────────────
  local min_list=""
  for i in 0 10 20 30 40 50; do
    printf -v mm "%02d" "$i"
    min_list+="$mm\n"
  done

  local minute
  minute=$(printf "$min_list" | rofi_run "Minute" -format 's') || return 1

  # ── Build datetime ───────────────────────────────────────
  local dt
  printf -v dt "%04d-%02d-%02d %02d:%02d" \
    "$current_year" "$month" "$day" "$hour" "$minute"

  local epoch
  epoch="$(to_epoch "$dt")"

  if [[ "$epoch" -eq 0 ]]; then
    send_notify normal "tasknotify" "Invalid date"
    return 1
  fi

  # ── Optional link ─────────────────────────────────────────
  local link
  link=$(echo "" | rofi_input "Insert link or blank") || link=""

  task_add "$name" "$dt" "$link"

  send_notify low \
    "Task added" \
    "$name  •  $(fmt_epoch "$epoch")"
}
# ── Task list / main menu ─────────────────────────────────────────────────────
ui_task_list() {
  local now
  now=$(date +%s)

  # Build display lines from sorted tasks
  local lines=()
  local ids=()

  while IFS= read -r task; do
    local id name epoch link done_flag
    id=$(echo "$task" | jq -r '.id')
    name=$(echo "$task" | jq -r '.name')
    epoch=$(echo "$task" | jq -r '.epoch')
    link=$(echo "$task" | jq -r '.link // ""')
    done_flag=$(echo "$task" | jq -r '.done')

    local dt_str
    dt_str="$(fmt_epoch "$epoch")"

    # Time delta label
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

    local tick="[ ]"
    [[ "$done_flag" == "true" ]] && tick="[✓]"

    lines+=("$tick  $name  •  $dt_str$delta$link_sym")
    ids+=("$id")
  done < <(tasks_sorted | jq -c '.[]')

  [[ ${#lines[@]} -eq 0 ]] && lines=("(no tasks)") && ids=("")

  # Add a footer action
  lines+=("── Add new task ──")
  ids+=("__add__")

  # Show rofi menu
  local chosen_line chosen_idx
  chosen_line=$(printf '%s\n' "${lines[@]}" |
    rofi_run "Tasks" -format 'i' -no-custom) || return 0

  # rofi -format i gives the index
  chosen_idx="$chosen_line"
  local chosen_id="${ids[$chosen_idx]:-}"

  if [[ "$chosen_id" == "__add__" ]]; then
    ui_add_task
    return 0
  fi

  [[ -z "$chosen_id" ]] && return 0

  # Task action submenu
  local task_json
  task_json=$(jq -c --arg id "$chosen_id" '.[] | select(.id == $id)' "$TASKS_FILE")
  local task_name task_link
  task_name=$(echo "$task_json" | jq -r '.name')
  task_link=$(echo "$task_json" | jq -r '.link // ""')

  local actions=("✓  Mark complete (remove)")
  [[ -n "$task_link" ]] && actions+=("🔗  Open link")
  actions+=("✎  Edit task" "✕  Cancel")

  local action
  action=$(printf '%s\n' "${actions[@]}" |
    rofi_run "$task_name" -no-custom) || return 0

  case "$action" in
  "✓"*)
    task_complete "$chosen_id"
    send_notify low "Task done" "$task_name"
    ;;
  "🔗"*) xdg-open "$task_link" &>/dev/null & ;;
  "✎"*) ui_edit_task "$chosen_id" ;;
  esac
}

# ── Edit task ─────────────────────────────────────────────────────────────────
ui_edit_task() {
  local id="$1"
  local task_json
  task_json=$(jq -c --arg id "$id" '.[] | select(.id == $id)' "$TASKS_FILE")

  local cur_name cur_dt cur_link
  cur_name=$(echo "$task_json" | jq -r '.name')
  cur_dt=$(echo "$task_json" | jq -r '.datetime')
  cur_link=$(echo "$task_json" | jq -r '.link // ""')

  local name dt link
  name=$(echo "$cur_name" | rofi_input "Edit name") || return 1
  [[ -z "$name" ]] && name="$cur_name"

  dt=$(echo "$cur_dt" | rofi_input "Edit deadline") || return 1
  [[ -z "$dt" ]] && dt="$cur_dt"

  link=$(echo "$cur_link" | rofi_input "Edit link (blank = keep)") || link="$cur_link"

  local epoch
  epoch="$(to_epoch "$dt")"

  jq --arg id "$id" \
    --arg name "$name" \
    --arg dt "$dt" \
    --argjson epoch "$epoch" \
    --arg link "$link" \
    'map(if .id == $id then
           .name = $name | .datetime = $dt | .epoch = $epoch | .link = $link
        else . end)' "$TASKS_FILE" | tasks_write
  log "EDIT [$id] -> $name @ $dt"
  send_notify low "Task updated" "$name"
}

# ── Notification daemon (called by systemd timer) ─────────────────────────────
run_checker() {
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
    [[ -n "$link" ]] && body="$body  •  $link"

    # 1) Day before  → window: 24h..25h before
    if [[ $diff -ge $((day)) && $diff -lt $((day + 3600)) ]]; then
      local key="${fired_key_base}_daybefore"
      if [[ ! -f "$key" ]]; then
        send_notify normal "Tomorrow: $name" "$body"
        touch "$key"
      fi
    fi

    # 2) Day of  → window: same calendar day, 8..9h before deadline OR at 08:00
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

    # 3) 1 hour before  → window: 1h..1h+5min
    if [[ $diff -ge 3600 && $diff -lt 3900 ]]; then
      local key="${fired_key_base}_1h"
      if [[ ! -f "$key" ]]; then
        send_notify critical "1 hour: $name" "$body"
        touch "$key"
      fi
    fi

    # 4) Deadline (overdue by 0..10min)
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
check) run_checker ;;
*)
  echo "Usage: tasknotify.sh [ui|add|check]"
  echo "  ui     — open rofi task manager (default)"
  echo "  add    — open add-task wizard directly"
  echo "  check  — run notification checker (used by systemd)"
  exit 1
  ;;
esac
