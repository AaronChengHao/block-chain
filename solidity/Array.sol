// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Array{
    uint256[] public arr;
    uint256[] public arr2=[1,2,3];

    uint256[10] public myFixedSizeArr;

    function get(uint256 i) public view  returns (uint256){
        return arr[i];
    }


    function push (uint256 i) public {
        arr.push(i);
    }

    function pop() public {
        arr.pop();
    }

    function getLength() public view   returns (uint256) {
        return arr.length;
    }

    function remove(uint256 indexe ) public {
        delete arr[indexe];
    }

    function examples() external pure returns (uint256[] memory) {
        uint256[] memory a = new uint256[](5);
        return a;
    }
}