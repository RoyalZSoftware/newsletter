#!/bin/bash

# compile_template <content>
compile_template() {
  local content="$1"
  shift

  # 2. Variablen ersetzen
  while [[ $# -gt 0 ]]; do
    local kv="$1"
    local key="${kv%%=*}"
    local val="${kv#*=}"
    # Ersetze {{key}} durch val im Markdown
    content="${content//\{\{$key\}\}/$val}"
    shift
  done

  # 3. Markdown in HTML wandeln
  local html=$(echo "$content" | lib/markdown2html.pl )

  # 4. Template laden (Variable TEMPLATE muss gesetzt sein)
  if [[ -z "$TEMPLATE" ]]; then
    echo "Error: TEMPLATE variable not set" >&2
    return 1
  fi

  # 5. Template mit %%CONTENT%% ersetzen
  while IFS= read -r line; do
    if [[ "$line" == *"%%CONTENT%%"* ]]; then
      printf '%s\n' "$html"
    else
      printf '%s\n' "$line"
    fi
  done < "$TEMPLATE"
}