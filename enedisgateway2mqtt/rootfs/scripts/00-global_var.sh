#!/bin/bash

###################################
# Export all addon options as env #
###################################

# For all keys in options.json
JSONSOURCE="/data/options.json"

# Export keys as env variables
# echo "All addon options were exported as variables"
mapfile -t arr < <(jq -r 'keys[]' ${JSONSOURCE})
for KEYS in ${arr[@]}; do
  # export key
  VALUE=$(jq .$KEYS ${JSONSOURCE})
  export ${KEYS}=${VALUE//[\"\']/} &>/dev/null
done

################
# Set timezone #
################
if [ ! -z "TZ" ] && [ -f /etc/localtime ]; then
  if [ -f /usr/share/zoneinfo/$TZ ]; then
    echo "Timezone set from $(cat /etc/timezone) to $TZ"
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
  else
    echo "WARNING : Timezone $TZ is invalid, it will be kept to default value of $(cat /etc/timezone)"
  fi
fi
