#!/bin/bash

SCRIPT_NAME="Keyblast.sh"
TARGET_DIR="/usr/local/bin"
ALIAS_NAME="keyblast"

if [[ $EUID -ne 0 ]]; then
   echo "sudo required, run: sudo ./install.sh"
   exit 1
fi

if [[ ! -f "$SCRIPT_NAME" ]]; then
    echo "error: '$SCRIPT_NAME' not found"
    echo "download again from: github.com/dotbillu/keyblast"
    exit 1
fi

chmod +x "$SCRIPT_NAME"
install -m 755 "$SCRIPT_NAME" "$TARGET_DIR/$ALIAS_NAME"

ALIAS_COMMAND="alias $ALIAS_NAME='$ALIAS_NAME'"
ZSHRC_FILE="$HOME/.zshrc"
BASHRC_FILE="$HOME/.bashrc"

add_alias() {
    local file=$1
    if [[ -f "$file" ]]; then
        if grep -q "alias $ALIAS_NAME=" "$file"; then
            echo "updating $file"
        else
            echo "$ALIAS_COMMAND" >> "$file"
            echo "updating $file"
        fi
    fi
}

add_alias "$ZSHRC_FILE"
add_alias "$BASHRC_FILE"

echo "installation done. restart your terminal and run: $ALIAS_NAME"

