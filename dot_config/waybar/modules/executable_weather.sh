#!/bin/bash

cachedir="$HOME/.cache/rbn"
cachefile="${0##*/}"
cache="$cachedir/$cachefile"

mkdir -p "$cachedir"

# Cache age in seconds
if [ -f "$cache" ]; then
  cacheage=$(($(date +%s) - $(stat -c '%Y' "$cache")))
else
  cacheage=999999
fi

# Refresh every 29 minutes
if [ "$cacheage" -gt 1740 ] || [ ! -s "$cache" ]; then
  curl -s 'https://wttr.in/Hanoi?format=%l\n%C\n%t&lang=en' |
    sed 's/\x1b\[[0-9;]*m//g' \
      >"$cache"
fi
# Read cache safely
mapfile -t weather <"$cache"

location="${weather[0]}"
condition_raw="$(echo "${weather[1]}" | xargs)"
temperature="$(echo "${weather[2]}" | xargs)"

condition=$(echo "$condition_raw" | tr '[:upper:]' '[:lower:]')

case "$condition" in
"clear" | "sunny")
  icon="☀️"
  ;;
"partly cloudy")
  icon="⛅"
  ;;
"cloudy" | "overcast")
  icon="☁️"
  ;;
"mist" | "fog" | "freezing fog")
  icon="🌫️"
  ;;
"patchy rain possible" | "patchy light drizzle" | "light drizzle" | "patchy light rain" | "light rain" | "light rain shower" | "rain")
  icon="🌦️"
  ;;
"moderate rain at times" | "moderate rain" | "heavy rain at times" | "heavy rain" | "moderate or heavy rain shower" | "torrential rain shower" | "rain shower")
  icon="🌧️"
  ;;
"patchy snow possible" | "patchy sleet possible" | "patchy freezing drizzle possible" | "freezing drizzle" | "heavy freezing drizzle" | "light freezing rain" | "moderate or heavy freezing rain" | "light sleet" | "ice pellets" | "light sleet showers" | "moderate or heavy sleet showers")
  icon="🌨️"
  ;;
"blowing snow" | "moderate or heavy sleet" | "patchy light snow" | "light snow" | "light snow showers")
  icon="❄️"
  ;;
"blizzard" | "patchy moderate snow" | "moderate snow" | "patchy heavy snow" | "heavy snow" | "moderate or heavy snow with thunder" | "moderate or heavy snow showers")
  icon="☃️"
  ;;
"thundery outbreaks possible" | "patchy light rain with thunder" | "moderate or heavy rain with thunder" | "patchy light snow with thunder")
  icon="⛈️"
  ;;
*)
  icon="🌡️"
  ;;
esac

tooltip="$location\nCondition: $condition_raw\nTemperature: $temperature"

printf '{"text":"%s","tooltip":"%s"}\n' \
  "$icon" \
  "$tooltip"
