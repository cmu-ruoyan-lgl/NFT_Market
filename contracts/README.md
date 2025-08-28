# NFT Marketplace Smart Contracts

这是一个完整的NFT市场智能合约系统，基于Foundry框架构建，支持NFT铸造、购买、出售和拍卖功能。

## 功能特性

- **NFT铸造**: 用户可以铸造新的NFT
- **市场交易**: 支持NFT的直接购买和出售
- **拍卖系统**: 完整的拍卖功能，包括出价和结束拍卖
- **平台费用**: 可配置的平台费用系统
- **权限管理**: 基于OpenZeppelin的访问控制
- **安全特性**: 重入攻击防护和安全的资金转移

## 合约架构

### NFTMarketplace.sol
主要的NFT市场合约，继承自：
- `ERC721`: 标准NFT代币
- `ERC721URIStorage`: NFT元数据存储
- `ReentrancyGuard`: 重入攻击防护
- `Ownable`: 访问控制

## 安装和设置

### 1. 安装依赖
```bash
forge install OpenZeppelin/openzeppelin-contracts
```

### 2. 环境配置
创建 `.env` 文件并设置以下环境变量：
```bash
# 部署者私钥
PRIVATE_KEY=your_private_key_here

# RPC端点
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your_api_key
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_api_key

# Etherscan API密钥（用于合约验证）
ETHERSCAN_API_KEY=your_etherscan_api_key_here

# 部署网络
DEPLOY_NETWORK=sepolia
```

### 3. 编译合约
```bash
forge build
```

### 4. 运行测试
```bash
forge test
```

### 5. 部署合约
```bash
# 设置环境变量
source .env

# 部署到Sepolia测试网
forge script script/Deploy.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# 部署到本地Anvil网络
anvil
forge script script/Deploy.sol:DeployScript --rpc-url http://localhost:8545 --broadcast
```

## 主要功能说明

### NFT铸造
```solidity
function mintNFT(string memory tokenURI) public returns (uint256)
```
- 铸造新的NFT
- 设置NFT的元数据URI
- 返回新铸造的NFT ID

### 创建市场项目
```solidity
function createMarketItem(uint256 tokenId, uint256 price) public payable
```
- 将NFT上架出售
- 设置出售价格
- 转移NFT到市场合约

### 购买NFT
```solidity
function buyMarketItem(uint256 tokenId) public payable
```
- 购买上架的NFT
- 自动计算并收取平台费用
- 转移NFT给买家

### 创建拍卖
```solidity
function createAuction(uint256 tokenId, uint256 startingPrice, uint256 duration) public
```
- 创建NFT拍卖
- 设置起拍价和持续时间
- 转移NFT到市场合约

### 出价
```solidity
function placeBid(uint256 tokenId) public payable
```
- 对拍卖中的NFT出价
- 自动退还之前的出价
- 更新最高出价记录

### 结束拍卖
```solidity
function endAuction(uint256 tokenId) public
```
- 结束拍卖并确定获胜者
- 自动转移NFT和资金
- 收取平台费用

## 查询功能

### 获取市场信息
- `getMarketItem(uint256 tokenId)`: 获取特定NFT的市场信息
- `getAllMarketItems()`: 获取所有未售出的市场项目
- `getMyNFTs(address user)`: 获取用户拥有的NFT
- `getMyCreatedNFTs(address user)`: 获取用户创建的NFT

## 管理功能

### 平台设置
- `setPlatformFeePercentage(uint256 newFeePercentage)`: 设置平台费用比例
- `setMinPrice(uint256 newMinPrice)`: 设置最低价格
- `withdraw()`: 提取平台费用

## 安全特性

- **重入攻击防护**: 使用OpenZeppelin的ReentrancyGuard
- **访问控制**: 基于OpenZeppelin的Ownable合约
- **安全的资金转移**: 使用pull模式进行资金转移
- **输入验证**: 全面的参数验证和错误处理

## 事件系统

合约发出以下事件来跟踪重要操作：
- `MarketItemCreated`: NFT上架
- `MarketItemSold`: NFT售出
- `AuctionCreated`: 拍卖创建
- `BidPlaced`: 出价记录
- `AuctionEnded`: 拍卖结束

## 测试

运行完整的测试套件：
```bash
forge test
```

运行特定测试：
```bash
forge test --match-test testMintNFT
```

运行测试并显示详细日志：
```bash
forge test -vvv
```

## 网络配置

### Sepolia测试网
```bash
forge script script/Deploy.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### 本地开发
```bash
# 启动本地节点
anvil

# 部署到本地网络
forge script script/Deploy.sol:DeployScript --rpc-url http://localhost:8545 --broadcast
```

## 合约验证

部署后验证合约：
```bash
forge verify-contract <CONTRACT_ADDRESS> src/NFTMarketplace.sol:NFTMarketplace --etherscan-api-key $ETHERSCAN_API_KEY --chain sepolia
```

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request来改进这个项目。
