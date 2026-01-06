#!/usr/bin/env bash

source .env

echo "Deploying Collector..."

echo "Deploy args:
FeeModule: $FEE_MODULE
Admin: $ADMIN
"

OUTPUT="$(forge script DeployCollector \
    --private-key $PK \
    --rpc-url $RPC_URL \
    --json \
    --broadcast \
    -s "run(address,address)" $ADMIN $FEE_MODULE)"

COLLECTOR=$(echo "$OUTPUT" | grep "{" | jq -r .returns.collector.value)
echo "Collector deployed at address: $COLLECTOR"

echo "Complete!"
