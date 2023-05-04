#!/usr/bin/env bash

source .env

echo "Deploying FeeModule..."

echo "Deploy args:
Exchange: $EXCHANGE
"

OUTPUT="$(forge script Deploy \
    --private-key $PK \
    --rpc-url $RPC_URL \
    --json \
    --broadcast \
    -s "deploy(address)" $EXCHANGE)"

MODULE=$(echo "$OUTPUT" | grep "{" | jq -r .returns.module.value)
echo "FeeModule deployed at address: $MODULE"

echo "Complete!"
