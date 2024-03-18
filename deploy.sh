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

# Deploy DenverAuctionNFT
echo "Deploying DenverAuctionNFT..."
# forge script ./script/DeployDenverAuctionNFT --broadcast --rpc-url $RPC_URL --private-key $PRIVATE_KEY -vvv
# forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --constructor-args $PUBLIC_ADDRESS --etherscan-api-key $ETHERSCAN_API_KEY --verify src/DenverAuctionNFT.sol:DenverAuctionNFT
forge script script/DenverAuctionNFT.s.sol:DeployDenverAuctionNFT --fork-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vvv

# Deploy EnglishAuction
echo "Deploying EnglishAuction..."
# forge script ./script/DeployEnglishAuction --broadcast --rpc-url $RPC_URL --private-key $PRIVATE_KEY -vvv
# forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --etherscan-api-key $ETHERSCAN_API_KEY --verify src/EnglishAuction.sol:EnglishAuction
forge script script/EnglishAuction.s.sol:DeployEnglishAuction --fork-url $ARBITRUM_RPC_URL --private-key $PRIVATE_KEY --broadcast --etherscan-api-key $ETHERSCAN_API_KEY --verify -vvv

echo "Deployment completed."
