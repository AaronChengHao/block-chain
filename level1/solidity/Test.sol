// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Test{

    function getCode() public view  returns ( bytes memory ){
        return address(this).code;
    }

    function getBalance()public view  returns (uint256) {
        return address(this).balance;
    }

    function getCodeHash() public  view  returns (bytes32){
        return address(this).codehash;
    }

    function addBalance()public  payable returns (uint256) {
        require(msg.value > 0, " money fail");
        return msg.value;
    }

    function transfer(address payable  _targetAddr) public {
        _targetAddr.transfer(1);
    }
}