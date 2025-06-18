#!/bin/bash
if [ "$BASE_DIR" = "" ]; then
    BASE_DIR=./test # can be overriden
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Bei Installation z. B. in /usr/local/bin, LIB_DIR auf /usr/local/share/newsletter setzen
if [ "$SCRIPT_DIR" = "/usr/local/bin" ]; then
    LIB_DIR="/usr/local/share/newsletter"
fi

source $LIB_DIR/abstract.mailservice.sh

CONTENT_DIR=$LIB_DIR/content
TEMPLATE=$CONTENT_DIR/template.html
MAIL_SERVICE=unset

if [ -f ~/.newsletter ]; then
    . ~/.newsletter
else
    cp .newsletter.example ~/.newsletter # override any settings in here.
fi

if [ "$MAIL_SERVICE" = "sendgrid" ]; then
    . $LIB_DIR/sendgrid.mailservice.sh
fi

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
mkdir -p $JOURNEYS_DIR

chown -R $(whoami) $BASE_DIR

source $LIB_DIR/errors.sh
source $LIB_DIR/cli.sh
source $LIB_DIR/templating.sh
source $LIB_DIR/subscription.sh
source $LIB_DIR/sending.sh
source $LIB_DIR/journeys.sh