function spec_subscribe {
    local email="$1"
    export CONTENT_DIR="$SPEC_DIR"
    export TEMPLATE="$SPEC_DIR/content_only_template.html"
    export MAIL_SERVICE="$SPEC_DIR/mail_mock.sh"

    local code=$(subscribe "$1" | sed -n 's:.*<p>\(.*\)</p>.*:\1:p')
    confirm "$1" $code
}
