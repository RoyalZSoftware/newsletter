#!/bin/bash

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
    shopt -u nullglob

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
    shopt -u nullglob

    for file in "${messages[@]}"; do
        read ts journey email <<< $(parse_outbox_filename "$file")

        if [[ $ts > $NOW ]]; then
            continue
        fi

        echo "Sending $file to $email"
        (send_file "$email" "$file")
        if [[ $? -eq 0 || $? -eq $ERR_NOT_SUBSCRIBED ]]; then
            rm $file
        fi
    done
}