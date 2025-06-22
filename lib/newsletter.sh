#!/bin/bash

# Bei Installation z. B. in /usr/local/bin, LIB_DIR auf /usr/local/share/newsletter setzen
source $LIB_DIR/abstract.mailservice.sh

CONTENT_DIR="${CONTENT_DIR:-$LIB_DIR/content}"
TEMPLATE="${TEMPLATE:-$CONTENT_DIR/template.html}"

if [[ -f ~/.newsletter ]]; then
    . ~/.newsletter
else
    cp .newsletter.example ~/.newsletter # override any settings in here.
fi

if [ "$MAIL_SERVICE" ]; then
    if [ "$MAIL_SERVICE" = "msmtp" ]; then
        . $LIB_DIR/msmtp.mailservice.sh
    else
        . $MAIL_SERVICE
    fi
fi

PENDING_DIR=$DATA_DIR/pending
SUBSCRIBED_DIR=$DATA_DIR/subscribed
OUTBOX_DIR=$DATA_DIR/outbox
JOURNEYS_DIR=$CONTENT_DIR/journeys

NOW=`date '+%F_%H_%M_%S'`

mkdir -p $DATA_DIR
mkdir -p $SUBSCRIBED_DIR
mkdir -p $PENDING_DIR
mkdir -p $OUTBOX_DIR || exit 1
mkdir -p $JOURNEYS_DIR

chown -R $(whoami) $DATA_DIR

source $LIB_DIR/errors.sh
source $LIB_DIR/utils.sh
source $LIB_DIR/cli.sh
source $LIB_DIR/templating.sh
source $LIB_DIR/subscription.sh
source $LIB_DIR/sending.sh
source $LIB_DIR/journeys.sh