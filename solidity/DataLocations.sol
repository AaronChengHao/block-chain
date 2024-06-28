// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract DataLocations{
    uint256[] public  arr;

    mapping (uint256 => address) map;

    struct MyStruct{
        uint256 foo;
    }

    mapping (uint256 => MyStruct) myStructs;

    function f() public {
        _f(arr, map, myStructs[1]);
    }

    function _f(uint256[] storage _arr, mapping(uint256 => address) storage _map, MyStruct storage _myStruct) internal  {
        // do something with storage variables
    }

    function g(uint256[] memory _arr) public  returns (uint256[] memory){
        // do something
    }

    function h(uint256[] calldata _arr) external   {
            // do something with calldata array
    }
}