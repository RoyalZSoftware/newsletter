#!/bin/bash

# _is_subscribed <email>
function _is_subscribed {
    is_strict_email $1
    [ -f $SUBSCRIBED_DIR/$1 ]
}

function _random_code {
    openssl rand -hex 4
}

# subscribe <email>
function subscribe {
    is_strict_email $1
    if _is_subscribed $1;
    then
        echo "Already subscribed"
        exit $ERR_ALREADY_SUBSCRIBED
    fi

    code=$(_random_code)
    echo $code > $PENDING_DIR/$1

    send_file "$1" $CONTENT_DIR/confirm_subscription.md code=$code
}

# confirm <email> <code>
function confirm {
    if ! [ -f "$PENDING_DIR/$1" ];
    then
        echo "Email is not registered."
        exit $ERR_NOT_SUBSCRIBED
    fi

    if ! [ $(cat "$PENDING_DIR/$1") = "$2" ];
    then
        echo "Code does not match"
        exit $ERR_CODES_DO_NOT_MATCH
    fi

    rm "$PENDING_DIR/$1"
    echo "Confirmed $NOW" > "$SUBSCRIBED_DIR/$1"
    echo "Successful subscribed"
}

# unsubscribe <email>
function unsubscribe {
    is_strict_email $1
    if ! [ -f $SUBSCRIBED_DIR/$1 ];
    then
        echo "Email is not subscribed."
        exit $ERR_NOT_SUBSCRIBED
    fi

    rm $SUBSCRIBED_DIR/$1
    echo "Successful unsubscribed"
    clear_journeys $1
}

function list {
    echo "Pending: $(ls $PENDING_DIR)"
    echo "Subscribed: $(ls $SUBSCRIBED_DIR)"
}