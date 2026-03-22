#!/bin/bash

word=$(wl-paste | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

[ -z "$word" ] && exit 0

# detect Japanese
if echo "$word" | grep -qP '[\p{Hiragana}\p{Katakana}\p{Han}]'; then
  # =========================
  # 🇯🇵 JAPANESE (Jisho clean)
  # =========================

  # =========================
  # 🇯🇵 JAPANESE (Jisho FIXED PROPERLY)
  # =========================

  html=$(curl -s "https://jisho.org/search/$word")

  # kanji word
  jp_word=$(echo "$html" |
    grep -oP '(?<=<span class="text">).*?(?=</span>)' |
    head -n 1)

  # meanings
  meanings=$(echo "$html" |
    grep -oP '(?<=<span class="meaning-meaning">).*?(?=</span>)' |
    head -5 |
    sed 's/<[^>]*>//g')

  formatted=$(echo "$meanings" | sed 's/^/- /')

  [ -z "$jp_word" ] && jp_word="$word"
  [ -z "$formatted" ] && formatted="No JP definition found"

  rofi -theme ~/.config/rofi/dict.rasi \
    -e "$jp_word$formatted"
else
  # =========================
  # 🇬🇧 ENGLISH (Cambridge)
  # =========================

  word_lower=$(echo "$word" | tr '[:upper:]' '[:lower:]')

  html=$(curl -s -A "Mozilla/5.0" \
    "https://dictionary.cambridge.org/dictionary/english/$word_lower")

  result=$(echo "$html" |
    grep -oP '(?<=<div class="def ddef_d db">).*?(?=</div>)' |
    head -n 1 |
    sed 's/<[^>]*>//g')

  [ -z "$result" ] && result="No EN definition found"

  rofi -theme ~/.config/rofi/dict.rasi \
    -e "$word_lower\n\n$result"
fi
