#!/bin/bash

function send_mail {
    local email="$1"
    local content="$2"
    local subject="${3:-Newsletter}"
    (echo "Subject: $subject!"; echo "Content-type: text/html"; echo; echo "$content") | msmtp "$email"
}
