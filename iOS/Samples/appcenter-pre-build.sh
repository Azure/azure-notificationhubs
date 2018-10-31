#!/usr/bin/env bash

INFO_PLIST=$APPCENTER_SOURCE_DIRECTORY/iOS/Samples/nhubsample/nhubsample/Info.plist

if [ "$NHUB_NAME" != "" ]; then
    plutil -replace NotificationHubName -string "$NHUB_NAME" $INFO_PLIST
fi

if [ "$NHUB_CONNECTIONSTRING" != "" ]; then
    plutil -replace NotificationHubConnectionString -string "$NHUB_CONNECTIONSTRING" $INFO_PLIST
fi

# Force sandbox notification environment
plutil -replace "aps-environment" -string "development" $APPCENTER_SOURCE_DIRECTORY/iOS/Samples/nhubsample/nhubsample/nhubsample.entitlements
