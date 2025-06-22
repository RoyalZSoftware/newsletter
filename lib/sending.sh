#!/bin/bash

# send <email> <content> <silent>
function send {
    local email="$1"
    local content="$2"
    shift
    shift

    is_strict_email "$email"
    local compiled_template=$(compile_template "$content" $*)
    send_mail "$email" "$compiled_template"
    if [ -f "$SUBSCRIBED_DIR/$1" ]; then
      echo "Sent email issue $2 at $NOW" >> "$SUBSCRIBED_DIR/$email"
    fi
}

# send_file <email> <path>
function send_file {
    local email="$1"
    local path="$2"
    shift
    shift

    local issue=$(cat $path) || {
        echo "Issue not found."
        exit $ERR_ISSUE_NOT_FOUND
    }

    send "$email" "$issue" $*
}

# _schedule_for <email> <journey> <content_path> <day_offset>
function _schedule_for {
    local email="$1"
    local journey="$2"
    local content_path="$3"
    local day_offset="$4"
    local send_at=$(add_days_to_now $day_offset)
    cp $content_path $OUTBOX_DIR/$(serialize_date $send_at).$journey.$(serialize_email $email).md
}

# send_to_all <file>
function send_to_all {
    local issue_path="$1"
    shift

    local users=("$SUBSCRIBED_DIR"/*)

    for user in $users; do
        local email=$(echo ${user##*/})
        send $email $issue_path $*
    done
}