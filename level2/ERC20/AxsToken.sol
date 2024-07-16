// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract AxsToken is ERC20Upgradeable {
    address public owner;
    function initialize() public {
        owner = msg.sender;
        __ERC20_init("Axs", "Axs");
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }


    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }
}
