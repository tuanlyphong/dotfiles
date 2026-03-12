#!/bin/bash
pid=$(hyprctl activewindow -j | jq '.pid')
[ -n "$pid" ] && kill -9 "$pid"
