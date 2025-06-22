#!/bin/bash

function send_mail {
    (echo "Subject: Newsletter!"; echo "Content-type: text/html"; echo; echo $2) | msmtp "$1"
}
