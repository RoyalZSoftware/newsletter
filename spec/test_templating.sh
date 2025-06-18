#!/bin/bash

function setup {
    $(rm -r test_data 2> /dev/null) || true
    export DATA_DIR=./test_data
}

function test_templating {
    export TEMPLATE="$SPEC_DIR/complex_template.html"
    export MAIL_SERVICE="$SPEC_DIR/mail_mock.sh"
    export CONTENT_DIR="$SPEC_DIR"

    ./bin/newsletter send_file panov@royalzsoftware.de $SPEC_DIR/template_fixture.md
}
