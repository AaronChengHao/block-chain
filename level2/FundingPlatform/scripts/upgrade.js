const {ethers, upgrades} = require("hardhat");

// 升级合约的部署代码
async function main(){
    const proxyAddr = "0xf83bA5E77bf88956f10da61F0CCe1741956c4AbE";
    const CrowdfundingPlatformV2 = await ethers.getContractFactory("CrowdFundingPlatformV2");
    const platform = await upgrades.upgradeProxy(proxyAddr, CrowdfundingPlatformV2);

    //   <!-- await platform.deployed();
    //   console.log("CrowdFundingPlatform deployed to:", platform.address);  updateBY leo-->
    await platform.waitForDeployment();
    console.log("CrowdFundingPlatform deployed to:", platform.target);


}

main();