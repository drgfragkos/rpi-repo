#!/usr/bin/env bash

PKG_LIST_FILE="pkg-hold-list.txt"

# Check if pkg-hold-list.txt exists
if [[ ! -f "$PKG_LIST_FILE" ]]; then
  echo "Error: File '$PKG_LIST_FILE' not found!"
  exit 1
fi

echo "=== Checking package presence and versions ==="
while IFS= read -r PACKAGE; do
  # Skip empty lines
  [[ -z "$PACKAGE" ]] && continue

  echo "Package: $PACKAGE"
  dpkg -l | grep "$PACKAGE" || echo "  - $PACKAGE not installed or not found in dpkg -l"
  echo
done < "$PKG_LIST_FILE"

echo "==============================================="
echo "Would you like to manage (hold/unhold) all packages at once,"
echo "or choose one by one?"
read -rp "Type 'all' or 'one': " USER_CHOICE

if [[ "$USER_CHOICE" == "all" ]]; then
  read -rp "Would you like to 'hold' or 'unhold' all packages? " HOLD_CHOICE

  while IFS= read -r PACKAGE; do
    [[ -z "$PACKAGE" ]] && continue

    if [[ "$HOLD_CHOICE" == "hold" ]]; then
      echo "Holding package: $PACKAGE"
      sudo apt-mark hold "$PACKAGE"
    elif [[ "$HOLD_CHOICE" == "unhold" ]]; then
      echo "Unholding package: $PACKAGE"
      sudo apt-mark unhold "$PACKAGE"
    else
      echo "Invalid choice. Skipping package: $PACKAGE"
    fi

  done < "$PKG_LIST_FILE"

elif [[ "$USER_CHOICE" == "one" ]]; then
  while IFS= read -r PACKAGE; do
    [[ -z "$PACKAGE" ]] && continue

    echo "--------------------------------------------"
    echo "Package: $PACKAGE"
    read -rp "Hold or unhold $PACKAGE? (hold/unhold/skip): " ACTION_CHOICE

    if [[ "$ACTION_CHOICE" == "hold" ]]; then
      echo "Holding $PACKAGE..."
      sudo apt-mark hold "$PACKAGE"
    elif [[ "$ACTION_CHOICE" == "unhold" ]]; then
      echo "Unholding $PACKAGE..."
      sudo apt-mark unhold "$PACKAGE"
    else
      echo "Skipping $PACKAGE."
    fi
    echo

  done < "$PKG_LIST_FILE"

else
  echo "Invalid option. Exiting."
  exit 1
fi

echo "Done!"
