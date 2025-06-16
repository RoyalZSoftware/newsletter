#!/bin/bash

PENDING_DIR=$BASE_DIR/pending
SUBSCRIBED_DIR=$BASE_DIR/subscribed
EMAIL_ISSUES_DIR=$BASE_DIR/issues

NOW=`date '+%F_%H:%M:%S'`

mkdir -p $BASE_DIR
mkdir -p $SUBSCRIBED_DIR
mkdir -p $PENDING_DIR
mkdir -p $EMAIL_ISSUES_DIR

chown -R $(whoami) $BASE_DIR

# compile_template <content>
function compile_template {
    local content=$(echo $1 | lib/markdown2html.pl)
    cat $TEMPLATE | sed "s/%%CONTENT%%/$1/"
}

function is_strict_email {
  local email="$1"
  
  if [[ "$email" =~ [/] ]]; then
    echo "Invalid email."
    exit 1
  fi

  if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    return 0
  else
    echo "Invalid email."
    exit 1
  fi
}

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
        exit 1
    fi

    CODE=$(_random_code)
    echo $CODE > $PENDING_DIR/$1
    echo $CODE
}

# confirm <email> <code>
function confirm {
    if ! [ -f "$PENDING_DIR/$1" ];
    then
        echo "Email is not registered."
        exit 1
    fi

    if ! [ $(cat "$PENDING_DIR/$1") = "$2" ];
    then
        echo "Code does not match"
        exit 1
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
        exit 1
    fi

    rm $SUBSCRIBED_DIR/$1
    echo "Successful unsubscribed"
}

# send <email> <issue_name>
function send {
    is_strict_email $1
    if ! _is_subscribed $1;
    then
        echo "Email is not subscribed."
        exit 1
    fi

    ISSUE=$(cat $EMAIL_ISSUES_DIR/$2 2> /dev/null) || {
        echo "Issue not found."
        exit 1
    }
    local compiled_template=$(compile_template $2)
    send_mail $1 "$compiled_template"
    echo "Sent email issue $2 at $NOW" >> $SUBSCRIBED_DIR/$1
}
