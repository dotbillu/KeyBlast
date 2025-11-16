#!/bin/bash

SCRIPT_NAME="Keyblast.sh"
TARGET_DIR="/usr/local/bin"
ALIAS_NAME="keyblast"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo to move files to $TARGET_DIR."
   echo "Running command: sudo ./install.sh"
   exit 1
fi

echo "--- Installation: Starting ---"
echo "1. Moving '$SCRIPT_NAME' to '$TARGET_DIR' (replacing if exists)..."

if [[ ! -f "$SCRIPT_NAME" ]]; then
    echo "Error: The script file '$SCRIPT_NAME' was not found in the current directory."
    exit 1
fi

chmod +x "$SCRIPT_NAME"
install -m 755 "$SCRIPT_NAME" "$TARGET_DIR/$ALIAS_NAME"

if [[ $? -eq 0 ]]; then
    echo "Success: '$SCRIPT_NAME' moved and renamed to '$ALIAS_NAME'. It is now globally executable from '$TARGET_DIR'."
else
    echo "Error: Failed to move the script. Installation aborted."
    exit 1
fi

echo ""
echo "2. Setting up permanent alias in shell configuration files..."

ALIAS_COMMAND="alias $ALIAS_NAME='$ALIAS_NAME'"
ZSHRC_FILE="$HOME/.zshrc"
BASHRC_FILE="$HOME/.bashrc"

add_alias() {
    local config_file=$1
    if [[ -f "$config_file" ]]; then
        if grep -q "alias $ALIAS_NAME=" "$config_file"; then
            echo "   -> Alias already exists in $config_file. Skipping."
        else
            echo "" >> "$config_file"
            echo "$ALIAS_COMMAND" >> "$config_file"
            echo "   -> Added alias to $config_file."
        fi
    fi
}

add_alias "$ZSHRC_FILE"
add_alias "$BASHRC_FILE"

echo ""
echo "--- Installation Complete! ---"
echo ""
echo "What was done:"
echo "The file '$SCRIPT_NAME' was moved to: '$TARGET_DIR/$ALIAS_NAME'."
echo "The following command was added as a permanent alias to your '$ZSHRC_FILE' and '$BASHRC_FILE' (if they exist):"
echo "$ALIAS_COMMAND"
echo ""
echo "To start using the command immediately, please run:"
echo "source $ZSHRC_FILE   (if you use Zsh)"
echo "source $BASHRC_FILE  (if you use Bash)"
echo ""
echo "After sourcing your config, simply type: $ALIAS_NAME"

