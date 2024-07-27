pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 奖励代币
contract RewardToken is ERC20{
    constructor()ERC20("RewardToken","RT"){}
    function mint(address _to,uint256 _amount)public{
        _mint(_to,_amount);
    }
}