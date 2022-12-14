#!/usr/bin/env bash

USERNAME=$1
PASSWORD=$2
SOURCEIMAGE=$3
CURRENTTAG=$4
TAGREGEX=$5

output=$(pwsh -file ./run-check.ps1 -un "${USERNAME}" -pat "${PASSWORD}" -si "${SOURCEIMAGE}" -ct "${CURRENTTAG}" -tfrgx "${TAGREGEX}")

changed=$(echo $output | cut -d'|' -f1)
tag=$(echo $output | cut -d'|' -f2)

echo "changed=${changed}" >> $GITHUB_OUTPUT
echo "tag=${tag}" >> $GITHUB_OUTPUT