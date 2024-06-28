// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Variables{
    string public test = "Hello";
    uint256 public num = 123;

    function deSomething() public view returns(uint256, uint256,address) {
        uint256 i = 456;

        uint256 timestamp = block.timestamp;
        address sender = msg.sender;
        return (i,timestamp,sender);
    }
}