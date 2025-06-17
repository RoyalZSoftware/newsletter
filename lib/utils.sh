#!/bin/bash

function serialize_email {
  local email="$1"
  echo "$email" | sed -e 's/@/_at_/g' -e 's/\./_dot_/g'
}

function deserialize_email {
  local safe="$1"
  echo "$safe" | sed -e 's/_dot_/\./g' -e 's/_at_/@/g'
}

serialize_date() {
  local input="$1"  # z.B. "now" oder "2025-06-17 14:30:00"
  if date -d "now" >/dev/null 2>&1; then
    # GNU date (Linux)
    date -u -d "$input" +"%Y-%m-%d_%H_%M_%S"
  else
    # BSD date (macOS)
    date -u -j -f "%Y-%m-%d_%H_%M_%S" "$input" +"%Y-%m-%d_%H_%M_%S"
  fi
}

deserialize_date() {
  local input="$1"  # z.B. "2025-06-17_14_30_00"
  local year="${input:0:4}"
  local month="${input:5:2}"
  local day="${input:8:2}"
  local hour="${input:11:2}"
  local min="${input:14:2}"
  local sec="${input:17:2}"

  local datestr="${year}-${month}-${day} ${hour}:${min}:${sec}"

  if date -d "now" >/dev/null 2>&1; then
    # GNU date (Linux)
    date -d "$datestr UTC"
  else
    # BSD date (macOS)
    date -u -j -f "%Y-%m-%d_%H_%M_%S" "$input" +"%Y-%m-%d_%H:%M:%S"

  fi
}


# create_outbox_filename <date> <journey> <email>
function create_outbox_filename {
    echo ""
}

function parse_outbox_filename {
    local filename=$(basename "$1")

    local timestamp="${filename%%.*}"
    local remainder="${filename#*.}"
    local journey="${remainder%%.*}"
    local email_serialized="${remainder#*.}"
    email_serialized="${email_serialized%.*}"

    echo "$(deserialize_date $timestamp)" "$journey" "$(deserialize_email $email_serialized)"
}

function add_days_to_now {
  local offset_days="$1"
  if date -d "now" >/dev/null 2>&1; then
    # GNU date (Linux)
    date -u -d "+${offset_days} days" +"%Y-%m-%d 09:00:00"
  else
    # BSD date (macOS)
    date -u -v+"${offset_days}"d +"%Y-%m-%d_09_00_00"
  fi
}