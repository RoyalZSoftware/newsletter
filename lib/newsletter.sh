#!/bin/bash

PENDING_DIR=$BASE_DIR/pending
SUBSCRIBED_DIR=$BASE_DIR/subscribed
EMAIL_ISSUES_DIR=$BASE_DIR/issues
OUTBOX_DIR=./var/newsletter/outbox
JOURNEYS_DIR=$CONTENT_DIR/journeys

NOW=`date '+%F_%H:%M:%S'`

mkdir -p $BASE_DIR
mkdir -p $SUBSCRIBED_DIR
mkdir -p $PENDING_DIR
mkdir -p $EMAIL_ISSUES_DIR
mkdir -p $OUTBOX_DIR

chown -R $(whoami) $BASE_DIR

# compile_template <content>
compile_template() {
  local md_path="$1"
  shift

  # 1. Markdown laden
  local md_content
  md_content=$(cat "$md_path")

  # 2. Variablen ersetzen
  while [[ $# -gt 0 ]]; do
    local kv="$1"
    local key="${kv%%=*}"
    local val="${kv#*=}"
    # Ersetze {{key}} durch val im Markdown
    md_content="${md_content//\{\{$key\}\}/$val}"
    shift
  done

  # 3. Markdown in HTML wandeln
  local html
  html=$(printf '%s\n' "$md_content" | lib/markdown2html.pl)

  # 4. Template laden (Variable TEMPLATE muss gesetzt sein)
  if [[ -z "$TEMPLATE" ]]; then
    echo "Error: TEMPLATE variable not set" >&2
    return 1
  fi

  # 5. Template mit %%CONTENT%% ersetzen
  while IFS= read -r line; do
    if [[ "$line" == *"%%CONTENT%%"* ]]; then
      printf '%s\n' "$html"
    else
      printf '%s\n' "$line"
    fi
  done < "$TEMPLATE"
}

function is_strict_email {
  local email="$1"
  
  if [[ "$email" =~ [/] ]]; then
    echo "Invalid email."
    exit $ERR_INVALID_EMAIL
  fi

  if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    return 0
  else
    echo "Invalid email."
    exit $ERR_INVALID_EMAIL
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
        exit $ERR_ALREADY_SUBSCRIBED
    fi

    code=$(_random_code)
    echo $code > $PENDING_DIR/$1

    compile_template $CONTENT_DIR/confirm_subscription.md code=$code
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
}

function list {
    echo "Pending: $(ls $PENDING_DIR)"
    echo "Subscribed: $(ls $SUBSCRIBED_DIR)"
}

# send <email> <path>
function send {
    local email="$1"
    local path="$2"
    shift
    shift

    is_strict_email "$email"
    if ! _is_subscribed "$email";
    then
        echo "Email is not subscribed."
        exit $ERR_NOT_SUBSCRIBED
    fi
    ISSUE=$(cat $path 2> /dev/null) || {
        echo "Issue not found."
        exit $ERR_ISSUE_NOT_FOUND
    }
    local compiled_template=$(compile_template "$path" $*)
    send_mail "$email" "$compiled_template"
    echo "Sent email issue $2 at $NOW" >> $SUBSCRIBED_DIR/$email
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

# _user_journeys <email>
function _user_journeys {
    local email=$(serialize_email "$1")
    local messages=($OUTBOX_DIR/*)
    local journeys=()

    for i in "${messages[@]}"; do
        # Zerlege Filename nach Punkt, nehme das 2. Feld als Journey
        # Beispiel Filename: ts.journey.email
        read -r ts journey email_file _ <<< "$(echo "$i" | sed -e 's/\./ /g')"
        # Prüfe, ob email_file die gesuchte email ist
        if [[ "$email_file" == "$email" ]]; then
            journeys+=("$journey")
        fi
    done

    # Duplikate entfernen und sortieren
    local unique_journeys=($(printf "%s\n" "${journeys[@]}" | sort -u))
    
    echo "${unique_journeys[@]}"
}

function user_in_journey {
    local user_email="$1"
    local search_journey="$2"

    local journeys=($(_user_journeys "$user_email"))

    for j in "${journeys[@]}"; do
        if [[ "$j" == "$search_journey" ]]; then
            return 0
        fi
    done

    return 1
}

# add_journey <email> <journey>
function add_journey {
    local email="$1"
    local journey="$2"
    if ! [ -f $SUBSCRIBED_DIR/$1 ]; then
        echo "User not subscribed."
        exit $ERR_NOT_SUBSCRIBED
    fi

    if user_in_journey "$email" "$journey"; then
        echo "User is already in journey $journey."
        exit $ERR_ALREADY_IN_JOURNEY
    fi

    if ! [ -d $JOURNEYS_DIR/$journey ]; then
        echo "Journey not found."
        exit $ERR_JOURNEY_NOT_FOUND
    fi
    shopt -s nullglob
    local messages=("$JOURNEYS_DIR/$journey"/*)

    for message in "${messages[@]}"; do
        local filename=${message##*/}
        local days_offset=${filename%.md}
        _schedule_for "$email" "$journey" "$message" "$days_offset"
    done
}

# remove_journey <email> <journey>
function remove_journey {
    is_strict_email "$1"
    local journey="$2"
    local serialized_email=$(serialize_email "$1")
    find $OUTBOX_DIR/ -type f -name "*.$journey.$serialized_email.md" -exec rm {} \;
}

# clear_journeys <email>
function clear_journeys {
    is_strict_email $1
    local serialized_email=$(serialize_email "$1")
    find $OUTBOX_DIR/ -type f -name "*.$serialized_email.md" -exec rm {} \;
}

function send_due {
    shopt -s nullglob
    local messages=("$OUTBOX_DIR"/*)

    for file in "${messages[@]}"; do
        read ts journey email <<< $(parse_outbox_filename "$file")

        if [[ $ts > $NOW ]]; then
            continue
        fi

        # send and remove
        echo "Sending $file to $email"
        (send "$email" "$file")
        if [[ $? -eq 0 || $? -eq $ERR_NOT_SUBSCRIBED ]]; then
            rm $file
        fi
    done
}

function usage {
    echo ""
    echo "Author: Alexander Panov <panov@royalzsoftware.de>"
    echo "GitHub: https://github.com/royalzsoftware/newsletter"
    echo ""
    echo "Newsletter CLI"
    echo ""
    echo "  newsletter list                   - print out newsletter subscribers"
    echo "  newsletter subscribe <email>      - subscribe to the newsletter"
    echo "  newsletter confirm <email> <code> - confirm subscription"
    echo "  newsletter unsubscribe <email>    - unsubscribe from newsletter"
    echo "  newsletter send <email> <issue>   - send <issue> to <email>"
    echo ""
}