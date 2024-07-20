// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakeToken is ERC20{
    constructor () ERC20("ST","ST"){}

    // 铸造代币
    function mint(address account, uint256 value) public  {
        _mint(account, value);
    }
}