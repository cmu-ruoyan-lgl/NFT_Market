#!/bin/bash

echo "🚀 Starting NFT Marketplace Demo..."

# 检查是否在contracts目录中
if [ ! -f "foundry.toml" ]; then
    echo "❌ Please run this script from the contracts directory"
    exit 1
fi

# 启动本地Anvil节点
echo "🔧 Starting local Anvil node..."
anvil --silent &
ANVIL_PID=$!

# 等待Anvil启动
sleep 3

# 设置环境变量
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export USER1_PRIVATE_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export USER2_PRIVATE_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

echo "📝 Deploying NFT Marketplace contract..."

# 部署合约
DEPLOY_OUTPUT=$(forge script script/DeployLocal.sol:DeployLocalScript --rpc-url http://localhost:8545 --broadcast --silent)

# 提取合约地址
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Contract Address:" | awk '{print $3}')

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "❌ Failed to deploy contract"
    kill $ANVIL_PID
    exit 1
fi

echo "✅ Contract deployed at: $CONTRACT_ADDRESS"

# 设置合约地址环境变量
export CONTRACT_ADDRESS=$CONTRACT_ADDRESS

echo "🎭 Running interaction demo..."

# 运行交互脚本
forge script script/Interact.sol:InteractScript --rpc-url http://localhost:8545 --broadcast --silent

echo ""
echo "🎉 Demo completed successfully!"
echo "📋 Contract Address: $CONTRACT_ADDRESS"
echo "🔗 You can now interact with the contract using this address"

# 停止Anvil
echo "🛑 Stopping Anvil node..."
kill $ANVIL_PID

echo "✨ Demo finished!"
