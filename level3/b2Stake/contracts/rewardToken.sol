// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20{
    constructor () ERC20("RT","RT"){}

    // 铸造代币
    // function mint(ddress account, uint256 value) public override {
    // }
}