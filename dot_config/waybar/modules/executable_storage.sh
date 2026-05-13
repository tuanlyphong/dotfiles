#!/bin/sh

warning=20
critical=10

df -k -P -l | awk -v warning=$warning -v critical=$critical '
$1 == "/dev/sda1" || $1 == "/dev/sdb2" {

  tooltip = tooltip \
  "Filesystem: "$1"\rSize: "$2/1024/1024 "G\rUsed: "$3/1024/1024 "G\rAvail: "$4/1024/1024 "G\rUse%: "$5"\rMounted on: "$6"\r\r"

  size=$2
  used=$3
  avail=$4
  use=$5

  gsub(/%/, "", use)

  total_size += size
  total_used += used
  total_avail += avail

  if ((100 - use) < critical) {
    class="critical"
  } else if ((100 - use) < warning && class != "critical") {
    class="warning"
  }
}

END {
  percentage = int((total_used / total_size) * 100)
  avail_gb = int(total_avail / 1024 / 1024)

  print "{\"text\":\"" avail_gb "G\", \"percentage\":" percentage ", \"tooltip\":\""tooltip"\", \"class\":\""class"\"}"
}
'
