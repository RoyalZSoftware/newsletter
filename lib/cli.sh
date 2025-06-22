#!/bin/bash

function is_strict_email {
  local email="$1"
  
  if [[ "$email" =~ [/] ]]; then
    echo "Invalid email."
    exit $ERR_INVALID_EMAIL
  fi

  if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    return 0
  else
    echo "Invalid email."
    exit $ERR_INVALID_EMAIL
  fi
}

function usage {
    echo ""
    echo "Author: Alexander Panov <panov@royalzsoftware.de>"
    echo "GitHub: https://github.com/royalzsoftware/newsletter"
    echo ""
    echo "Newsletter CLI"
    echo ""
    echo "  newsletter list                             - print out newsletter subscribers"
    echo "  newsletter subscribe <email> [journey]      - subscribe to the newsletter with optional a initial journey"
    echo "  newsletter confirm <email> <code>           - confirm subscription"
    echo "  newsletter unsubscribe <email>              - unsubscribe from newsletter"
    echo "  newsletter send <email> <file>              - send <issue> to <email>"
    echo "  newsletter add_journey <email> <journey>    - send <issue> to <email>"
    echo "  newsletter remove_journey <email> <journey> - send <issue> to <email>"
    echo "  newsletter clear_journeys <email>           - send <issue> to <email>"
    echo ""
}