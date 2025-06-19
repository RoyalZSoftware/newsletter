#!/bin/bash

function setup {
    $(rm -r test_data 2> /dev/null) || true
    export DATA_DIR=./test_data
    export MAIL_SERVICE="$SPEC_DIR/mail_mock.sh"
    export TEMPLATE="$SPEC_DIR/content_only_template.html"
    export CONTENT_DIR="$SPEC_DIR"
    export OUTBOX_DIR="$DATA_DIR/outbox"
    export EMAIL="panov@royalzsoftware.de"

    source $SPEC_DIR/spec_utils.sh
}

function test_journey_flow {
    spec_subscribe $EMAIL
    ./bin/newsletter add_journey $EMAIL gitlab
    assert_equals 0 $?
    assert_equals 2 $(ls $OUTBOX_DIR | wc -l)
    ./bin/newsletter send_due
    assert_equals 1 $(ls $OUTBOX_DIR | wc -l)
}

function test_adding_unsubscribed_user_to_journey_should_not_work {
    ./bin/newsletter add_journey $EMAIL gitlab
    assert_equals $ERR_NOT_SUBSCRIBED $?
}

function test_remove_journey_flow {
    spec_subscribe $EMAIL

    ./bin/newsletter add_journey $EMAIL gitlab
    assert_equals 2 $(ls $OUTBOX_DIR | wc -l)

    ./bin/newsletter remove_journey $EMAIL gitlab
    assert_equals 0 $?

    assert_equals 0 $(ls $OUTBOX_DIR | wc -l)
}

function test_unsubscribe_should_remove_journeys {
    spec_subscribe $EMAIL

    ./bin/newsletter add_journey $EMAIL gitlab
    assert_equals 0 $?
    assert_equals 2 $(ls $OUTBOX_DIR | wc -l)

    ./bin/newsletter unsubscribe $EMAIL
    assert_equals 0 $?
    ./bin/newsletter send_due || true
    assert_equals 0 $(ls $OUTBOX_DIR | wc -l)
}

function test_adding_user_to_the_ongoing_journey_twice_should_not_work {
    spec_subscribe $EMAIL
    ./bin/newsletter add_journey $EMAIL gitlab
    assert_equals 0 $?
    ./bin/newsletter add_journey $EMAIL gitlab
    assert_equals $ERR_ALREADY_IN_JOURNEY $?

    ./bin/newsletter send_due # will still leave one open newsletter issue to send
    assert_equals 1 $(ls $OUTBOX_DIR | wc -l)
    ./bin/newsletter add_journey $EMAIL gitlab
    assert_equals $ERR_ALREADY_IN_JOURNEY $?

    ./bin/newsletter unsubscribe $EMAIL
}

function cleanup {
    rm -r $DATA_DIR 2> /dev/null || true
}