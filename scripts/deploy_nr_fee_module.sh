#!/usr/bin/env bash

source .env

echo "Deploying NegRiskFeeModule..."

echo "Deploy args:
Admin: $ADMIN
NegRiskCTFExchange: $NR_CTF_EXCHANGE
NegRiskCTFAdapter: $NR_CTF_ADAPTER
CTF: $CTF
"

OUTPUT="$(forge script DeployNegRiskFeeModule \
    --private-key $PK \
    --rpc-url $RPC_URL \
    --json \
    --broadcast \
    -s "run(address,address,address,address)" $ADMIN $NR_CTF_EXCHANGE $NR_CTF_ADAPTER $CTF)"

MODULE=$(echo "$OUTPUT" | grep "{" | jq -r .returns.module.value)
echo "NegRiskFeeModule deployed at address: $MODULE"

echo "Complete!"
