#!/usr/bin/env bash
# UK Fis / FormaClube — App Privacy (Data Not Linked to You).
# Prereqs: asc web session for the UK Fis Apple ID + ASC_APP_ID in env.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FILE="$ROOT/OUTPUTS/asc/privacy.json"
APP_ID="${ASC_APP_ID:?Set ASC_APP_ID (App Store Connect Apple ID numeric)}"
APPLE_ID="${ASC_WEB_APPLE_ID:?Set ASC_WEB_APPLE_ID (UK Fis login email)}"
PROVIDER="${ASC_PUBLIC_PROVIDER_ID:-Q7N4M8H2WK}"

asc web privacy plan --app "$APP_ID" --file "$FILE" --apple-id "$APPLE_ID" --public-provider-id "$PROVIDER"
asc web privacy apply --app "$APP_ID" --file "$FILE" --apple-id "$APPLE_ID" --public-provider-id "$PROVIDER" --allow-deletes --confirm
asc web privacy publish --app "$APP_ID" --apple-id "$APPLE_ID" --public-provider-id "$PROVIDER" --confirm
