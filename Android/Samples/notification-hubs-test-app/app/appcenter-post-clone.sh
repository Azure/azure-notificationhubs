#!/usr/bin/env bash

OUTPUT_PATH=$APPCENTER_SOURCE_DIRECTORY/Android/Samples/notification-hubs-test-app/app/google-services.json

echo $GOOGLE_SERVICES_JSON > $OUTPUT_PATH

echo "Writing google-services.json: $OUTPUT_PATH"
echo "GOOGLE_SERVICE_JSON: ${GOOGLE_SERVICES_JSON:0:20}..."

