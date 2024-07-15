const { ethers, upgrades } = require("hardhat");

async function main() {
    const ownerAddr = "0xBa8595ba09EEF9772e87a2a90A2F09d7b95757CA";
    const CrowdfundingPlatform = await ethers.getContractFactory("CrowdFundingPlatform");
    const platform = await upgrades.deployProxy(CrowdfundingPlatform, [ownerAddr], { initializer: "initialize" });

    //   <!-- await platform.deployed();
    //   console.log("CrowdFundingPlatform deployed to:", platform.address);  updateBY leo-->
    await platform.waitForDeployment();
    console.log("CrowdFundingPlatform deployed to:", platform.target);
}

main();