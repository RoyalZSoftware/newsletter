#!/bin/bash

function setup {
    $(rm -r test_data 2> /dev/null) || true
    export DATA_DIR=./test_data
}

function test_shell_injection {
    local email="panov@royalzsoftware.de"
    (./bin/newsletter subscribe "$email; whoami")
    spec_subscribe "$email"
    ./bin/newsletter add_journey "$email" 'gitlab" && $(echo "Hello World"); whoami'
}

function cleanup {
    $(rm -r test_data 2> /dev/null) || true
    export DATA_DIR=./test_data
}