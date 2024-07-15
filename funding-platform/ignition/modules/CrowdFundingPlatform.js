const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");



const {ethers, upgrades} = require("hardhat");





module.exports = buildModule("CrowdFundingPlatform", (m) => {
  const platform = m.contract("CrowdFundingPlatform");

  return { platform };
});
