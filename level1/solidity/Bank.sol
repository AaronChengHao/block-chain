// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Bank{
    address public immutable owner;

    event Deposit(address _ads, uint256 amount);
    event Withdraw(uint256 amount);

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    constructor() payable {
        owner = msg.sender;
    }

    function withdraw() external {
        require(msg.sender == owner, "not owner");
        emit Withdraw(address(this).balance);
        selfdestruct(payable(msg.sender));
    }

    function getBalance()public view returns (uint256) {
        return address(this).balance;
    }
}