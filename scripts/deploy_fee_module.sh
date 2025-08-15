#!/usr/bin/env bash

source .env

echo "Deploying FeeModule..."

echo "Deploy args:
Exchange: $EXCHANGE
Admin: $ADMIN
"

OUTPUT="$(forge script DeployFeeModule \
    --private-key $PK \
    --rpc-url $RPC_URL \
    --json \
    --broadcast \
    -s "run(address,address)" $ADMIN $EXCHANGE)"

MODULE=$(echo "$OUTPUT" | grep "{" | jq -r .returns.module.value)
echo "FeeModule deployed at address: $MODULE"

echo "Complete!"
