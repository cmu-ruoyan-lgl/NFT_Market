// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/NFTMarketplace.sol";

contract DeployLocalScript is Script {
    function run() external {
        // 获取部署者私钥（从环境变量或使用默认值）
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        vm.startBroadcast(deployerPrivateKey);

        // 部署NFT市场合约
        NFTMarketplace marketplace = new NFTMarketplace();
        
        console.log("=== NFT Marketplace Deployed Successfully ===");
        console.log("Contract Address:", address(marketplace));
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Network: Local Anvil");
        console.log("=============================================");

        vm.stopBroadcast();
    }
}
