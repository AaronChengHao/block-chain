// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UpgradeableDemo is Initializable {
    uint256 public a;

    // 初始化函数, 后面的修饰符 initiablizer 来自 Initiablizable.sol
    // 用于限制该函数只能调用一次
    function initialize(uint256 _a) public initializer{
        a = _a;
    }

    function increaseA()external{
        ++a;
    }

}