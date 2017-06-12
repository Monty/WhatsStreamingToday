#! /bin/bash
# Remove all files and directories created by running scripts

echo "Answer y to delete, anything else to skip. Deletion cannot be undone!"
echo ""

# Allow use of switches -v or -i to be used with rm command
if [ "$1" == '-v' ] || [ "$1" == '-i' ]; then
    SWITCH="$1"
else
    SWITCH=""
fi

read -r -p "Delete all primary spreadsheet files? [y/N] " YESNO
if [ "$YESNO" != "y" ]; then
    echo "Skipping..."
else
    echo "Deleting ..."
    rm -f $SWITCH Acorn_TV_Shows*.csv MHz_TV_Shows*.csv
fi
echo ""

read -r -p "Delete all secondary spreadsheet files? [y/N] " YESNO
if [ "$YESNO" != "y" ]; then
    echo "Skipping..."
else
    echo "Deleting ..."
    rm -rf $SWITCH Acorn-columns MHz-columns
fi
echo ""

read -r -p "Delete all diff results? [y/N] " YESNO
if [ "$YESNO" != "y" ]; then
    echo "Skipping..."
else
    echo "Deleting ..."
    rm -f $SWITCH Acorn_diffs*.txt MHz_diffs*.txt
fi
echo ""

read -r -p "Delete all diff baselines? [y/N] " YESNO
if [ "$YESNO" != "y" ]; then
    echo "Skipping..."
else
    echo "Deleting ..."
    rm -rf $SWITCH Acorn-baseline MHz-baseline
fi
echo ""
