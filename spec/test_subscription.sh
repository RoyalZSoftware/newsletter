#!/bin/bash

function setup {
    $(rm -r test_data 2> /dev/null) || true
    export DATA_DIR=./test_data
}

function test_subscription_flow {
    export MAIL_SERVICE="$SPEC_DIR/mail_mock.sh"
    export TEMPLATE="$SPEC_DIR/content_only_template.html"
    export CONTENT_DIR="$SPEC_DIR"

    local code=$(./bin/newsletter subscribe panov@royalzsoftware.de | sed -n 's:.*<p>\(.*\)</p>.*:\1:p')
    ./bin/newsletter confirm panov@royalzsoftware.de $code
    ./bin/newsletter unsubscribe panov@royalzsoftware.de
}

function cleanup {
    rm -r $DATA_DIR 2> /dev/null || true
}