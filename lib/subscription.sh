#!/bin/bash

# _is_subscribed <email>
function _is_subscribed {
    is_strict_email $1
    [ -f "$SUBSCRIBED_DIR/$1" ]
}

function _random_code {
    openssl rand -hex 4
}

# subscribe <email> <initial_journey>
function subscribe {
    is_strict_email "$1"
    if _is_subscribed "$1";
    then
        echo "Already subscribed"
        exit $ERR_ALREADY_SUBSCRIBED
    fi

    _ensure_journey_exists "$2"
    code=$(_random_code)
    echo $code > "$PENDING_DIR/$1"
    echo "$2" >> "$PENDING_DIR/$1"

    send_file "$1" $CONTENT_DIR/confirm_subscription.md code=$code
}

function _get_initial_journey {
    is_strict_email "$1"
    local email="$1"

    local journey=$(sed -n '2p' "$PENDING_DIR/$1")
    echo "$journey"
}

# confirm <email> <code>
function confirm {
    if ! [ -f "$PENDING_DIR/$1" ];
    then
        echo "Email is not registered."
        exit $ERR_NOT_SUBSCRIBED
    fi

    if ! [[ $(sed -n '1p' "$PENDING_DIR/$1") == "$2" ]];
    then
        echo "Code does not match"
        exit $ERR_CODES_DO_NOT_MATCH
    fi

    local initial_journey=$(_get_initial_journey "$1")

    rm "$PENDING_DIR/$1"
    echo "$NOW: Confirmed" > "$SUBSCRIBED_DIR/$1"

    if ! [[ "$initial_journey" == "" ]]; then
        add_journey "$1" "$initial_journey"
        echo "$NOW: Addded to journey: $initial_journey" >> "$SUBSCRIBED_DIR/$1"
    fi

    send_due
    echo "Successful subscribed"
}

# unsubscribe <email>
function unsubscribe {
    is_strict_email $1
    if ! [ -f "$SUBSCRIBED_DIR/$1" ];
    then
        echo "Email is not subscribed."
        exit $ERR_NOT_SUBSCRIBED
    fi

    rm "$SUBSCRIBED_DIR/$1"
    echo "Successful unsubscribed"
    clear_journeys $1
}

function list {
    echo "Pending: $(ls $PENDING_DIR)"
    echo "Subscribed: $(ls "$SUBSCRIBED_DIR")"
}