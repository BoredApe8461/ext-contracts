#!/bin/bash

# Load environment variables from .env file
if [ -f .env.local ]; then
    export $(cat .env.local | sed 's/#.*//g' | xargs)
else 
    echo ".env file not found"
    exit 1
fi

# Compile the contracts
echo "Compiling contracts..."
forge build

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Build successful."
else
    echo "Build failed. Exiting..."
    exit 1
fi

# List of all RPC URLs
# declare -a RPC_URLS=("$SEPOLIA_RPC_URL" "$LINEA_RPC_URL" "$MUMBAI_RPC_URL" "$ARBITRUM_RPC_URL" "$MOONBEAM_RPC_URL" "$BASE_RPC_URL")
declare -a RPC_URLS=("$ARBITRUM_RPC_URL")

# Deploy contracts to all endpoints
for RPC_URL in "${RPC_URLS[@]}"
do
    echo "Deploying DenverAuctionNFT to network with RPC URL: $RPC_URL"
    forge script script/DenverAuctionNFT.s.sol:DeployDenverAuctionNFT --fork-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vvv

    echo "Deploying EnglishAuction to network with RPC URL: $RPC_URL"
    forge script script/EnglishAuction.s.sol:DeployEnglishAuction --fork-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vvv
done

echo "Deployment completed."
