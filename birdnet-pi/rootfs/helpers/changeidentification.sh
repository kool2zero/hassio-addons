#!/bin/bash

# This scripts allows to change the identification of a Birdnet-pi detection

#################
# SET VARIABLES #
#################

echo "starting"

HOME="/home/pi"
source /etc/birdnet/birdnet.conf &>/dev/null

# Get arguments
OLDNAME="$1" #OLDNAME="Mésange_charbonnière-78-2024-05-02-birdnet-RTSP_1-18:14:08.mp3"
NEWNAME="$2" #NEWNAME="Lapinus atricapilla_Lapinu à tête noire"

# Set log level
OUTPUT_TYPE="$3" #Can be : null (only errors output), debug (all outputs), or newname (errors and newname file)
if [ -z "$OUTPUT_TYPE" ]; then OUTPUT_TYPE="debug"; fi

# Ask for user input if no arguments
if [ -z "$OLDNAME" ]; then read -r -p 'OLDNAME (finishing by mp3): ' OLDNAME; fi
if [ -z "$NEWNAME" ]; then read -r -p 'NEWNAME (sciname_commoname): ' NEWNAME; fi

# Fixed values
LABELS_FILE="$HOME/BirdNET-Pi/model/labels.txt"
DB_FILE="$HOME/BirdNET-Pi/scripts/birds.db"
DETECTIONS_TABLE="detections"

###################
# VALIDITY CHECKS #
###################

# Check if files exist
if [ ! -f "$LABELS_FILE" ]; then echo "$LABELS_FILE doesn't exist, exiting" && exit 1; fi
if [ ! -f "$DB_FILE" ]; then echo "$DB_FILE doesn't exist, exiting" && exit 1; fi

# Check if inputs are valid
if [[ "$1" != *".mp3" ]]; then
  echo "The first argument should be a filename starting with the common name of the bird and finishing by mp3!"
  echo "Instead, it is : $1"
  exit 1
elif [[ "$2" != *"_"* ]]; then
  echo "The second argument should be in the format : \"scientific name_common name\""
  echo "Instead, it is : $2"
  exit 1
fi

# Check if $NEWNAME is found in the file $LABELS_FILE
if ! grep -q "$NEWNAME" "$LABELS_FILE"; then
    echo "Error: $NEWNAME not found in $LABELS_FILE"
    exit 1
fi

##################
# EXECUTE SCRIPT #
##################

# Get the line where the column "File_Name" matches exactly $OLDNAME
IFS='|' read -r OLDNAME_sciname OLDNAME_comname OLDNAME_date < <(sqlite3 "$DB_FILE" "SELECT Sci_Name, Com_Name, Date FROM $DETECTIONS_TABLE WHERE File_Name = '$OLDNAME' LIMIT 1;")

if [[ -z "$OLDNAME_sciname" ]]; then
    echo "Error: No line matching $OLDNAME in $DB_FILE"
    exit 1
fi

# Extract the part before the _ from $NEWNAME
NEWNAME_comname="${NEWNAME#*_}"
NEWNAME_sciname="${NEWNAME%%_*}"

# Replace spaces with underscores
NEWNAME_comname2="${NEWNAME_comname// /_}"
OLDNAME_comname2="${OLDNAME_comname// /_}"

# Replace OLDNAME_comname2 with NEWNAME_comname2 in OLDNAME
NEWNAME_filename="${OLDNAME//$OLDNAME_comname2/$NEWNAME_comname2}"

[[ "$OUTPUT_TYPE" == "debug" ]] && echo "This script will change the identification $OLDNAME from $OLDNAME_comname to ${NEWNAME#*_}"

########################
# EXECUTE : MOVE FILES #
########################

# Check if the file exists
FILE_PATH="$HOME/BirdSongs/Extracted/By_Date/$OLDNAME_date/$OLDNAME_comname2/$OLDNAME"
if [[ -f $FILE_PATH ]]; then
    # Ensure the new directory exists
    NEW_DIR="$HOME/BirdSongs/Extracted/By_Date/$OLDNAME_date/$NEWNAME_comname2"
    mkdir -p "$NEW_DIR"
    
    # Move and rename the file
    mv "$FILE_PATH" "$NEW_DIR/$NEWNAME_filename"
    mv "$FILE_PATH".png "$NEW_DIR/$NEWNAME_filename".png
    
    [[ "$OUTPUT_TYPE" == "debug" ]] && echo "Files moved!"
    # Outputs new filename
	echo "OK;$NEWNAME_filename"

else
    echo "Error: File $FILE_PATH does not exist"
fi

###################################
# EXECUTE : UPDATE DATABASE FILES #
###################################

# Update the database
sqlite3 "$DB_FILE" "UPDATE $DETECTIONS_TABLE SET Sci_Name = '$NEWNAME_sciname', Com_Name = '$NEWNAME_comname', File_Name = '$NEWNAME_filename' WHERE File_Name = '$OLDNAME';"

[[ "$OUTPUT_TYPE" == "debug" ]] && echo "Database entry removed"

[[ "$OUTPUT_TYPE" == "debug" ]] && echo "All done!"
