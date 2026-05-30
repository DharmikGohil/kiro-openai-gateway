#!/bin/sh

echo "$KIRO_CREDS_JSON" > /tmp/kiro-auth-token.json

export KIRO_CREDS_FILE=/tmp/kiro-auth-token.json

python main.py
