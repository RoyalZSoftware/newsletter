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
    add_journey $EMAIL gitlab
    assert_equals 0 $? "The command should succeed."
    assert_equals 2 $(ls $OUTBOX_DIR | wc -l) "The outbox dir should contain two emails to send"
    send_due
    assert_equals 1 $(ls $OUTBOX_DIR | wc -l) "The outbox dir should now contain only one email to send"
}

function test_adding_unsubscribed_user_to_journey_should_not_work {
    (add_journey $EMAIL gitlab)
    assert_equals $ERR_NOT_SUBSCRIBED $? "The program should exit, because the email is not subscribed."
}

function test_remove_journey_flow {
    spec_subscribe $EMAIL

    add_journey $EMAIL gitlab
    assert_equals 2 $(ls $OUTBOX_DIR | wc -l) "The outbox dir should now have two emails from the gitlab journey."

    remove_journey $EMAIL gitlab
    assert_equals 0 $? "The command should succeed."

    assert_equals 0 $(ls $OUTBOX_DIR | wc -l) "The outbox dir should now be empty."
}

function test_unsubscribe_should_remove_journeys {
    spec_subscribe $EMAIL

    add_journey $EMAIL gitlab
    assert_equals 0 $? "The command should succeed."
    assert_equals 2 $(ls $OUTBOX_DIR | wc -l) "The outbox dir should now contain two emails from the gitlab journey."

    unsubscribe $EMAIL
    assert_equals 0 $? "The command should succeed."
    send_due || true
    assert_equals 0 $(ls $OUTBOX_DIR | wc -l) "There should be no emails left in the outbox dir after unsubscription."
}

function test_adding_user_to_the_ongoing_journey_twice_should_not_work {
    spec_subscribe $EMAIL
    add_journey $EMAIL gitlab
    assert_equals 0 $? "add_journey should succeed."
    (add_journey $EMAIL gitlab)
    assert_equals $ERR_ALREADY_IN_JOURNEY $? "add_journey should fail because the user is already in the same journey."

    send_due # will still leave one open newsletter issue to send
    assert_equals 1 $(ls $OUTBOX_DIR | wc -l) "The outbox dir should now only contain one more email to send"
    (add_journey $EMAIL gitlab)
    assert_equals $ERR_ALREADY_IN_JOURNEY $? "The program should exit because there is still one email left to send from that journey."

    unsubscribe $EMAIL
}

function test_when_user_subscribes_to_journey_it_should_be_added_after_confirmation {
    local code=$(subscribe $EMAIL welcome |  sed -n 's:.*<p>\(.*\)</p>.*:\1:p')
    assert_equals 0 $(ls $OUTBOX_DIR | wc -l) "The outbox dir should be empty."
    function send_due() {
        echo "Do not directly send after confirmation, rather keep it for inspection."
    }
    confirm $EMAIL $code
    assert_equals 1 $(ls $OUTBOX_DIR | wc -l) "After confirmation the issues of the welcome journey should be in the OUTBOX for $EMAIL"
}

function test_when_user_subscribes_to_a_journey_that_does_not_exist_a_error_should_be_thrown {
    (subscribe $EMAIL not_existent)
    assert_equals $ERR_JOURNEY_NOT_FOUND $? "The journey is non existent and the app should fail with err code $ERR_JOURNEY_NOT_FOUND"
}

function test_when_clearing_journey_for_user_it_should_not_remove_other_users_journeys {
    spec_subscribe $EMAIL
    spec_subscribe seconduser@example.com

    (add_journey $EMAIL welcome)
    (add_journey seconduser@example.com welcome)

    assert_equals 2 $(ls $OUTBOX_DIR | wc -l) "The outbox dir should contain the one welcome email for both users."
}

function cleanup {
    rm -r $DATA_DIR 2> /dev/null || true
}