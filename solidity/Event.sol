// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;



contract Event{
    event Log(address indexed sender,string message);
    event AnotherLog();

    function test() public {
        emit Log(msg.sender, "hello World!");
        emit Log(msg.sender, "hello EVM");
        emit AnotherLog();
    }
}