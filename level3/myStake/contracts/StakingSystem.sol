// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//质押系统
contract StakingSystem {
    // 质押的 NFT 代币
    IERC721 public stakedNFT;
    // 质押奖励的 token 代币
    IERC20 public rewardsToken;

    // 质押周期
    uint256 stakingTime;

    // 质押者结构体
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) lockPeriod;
        uint256 pendingRewards;
        uint256 totalRewardsClaimed;
    }

    // 质押者映射集合
    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public tokenOwner;

    event StakedSuccess(address owner, uint256 tokenId);
    event RewardsClaimed(address indexed user, uint256 reward);
    event UnstakedSuccess(address owner, uint256 tokenId);

    constructor(IERC721 _stakedNFT, IERC20 _rewardToken) {
        stakedNFT = _stakedNFT;
        rewardsToken = _rewardToken;
    }

    // 质押
    function stake(uint256 _tokenId) public {
        require(stakedNFT.ownerOf(_tokenId) == msg.sender, "user must be the owner of the token");
        Staker storage staker = stakers[msg.sender];
        staker.tokenIds.push(_tokenId);
        staker.lockPeriod[_tokenId] = block.timestamp;
        tokenOwner[_tokenId] = msg.sender;
        stakedNFT.approve(address(this), _tokenId);
        stakedNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        emit StakedSuccess(msg.sender, _tokenId);
    }

    // 计算奖励
    function calculateReward(address _user) public {
        Staker storage staker = stakers[_user];
        uint256[] storage ids = staker.tokenIds;
        for (uint256 i = 0; i < ids.length; i++) {
            if (staker.lockPeriod[ids[i]] > 0 &&
                block.timestamp > staker.lockPeriod[ids[i]] + stakingTime) {
                uint256 stakedPeriod = (block.timestamp - staker.lockPeriod[ids[i]]) / stakingTime;
                staker.pendingRewards += 10e18 * stakedPeriod;
                uint256 remainingTime = (block.timestamp - staker.lockPeriod[ids[i]]) % stakingTime;
                staker.lockPeriod[ids[i]] = block.timestamp + remainingTime;
            }
        }
    }

    // 提取奖励
    function claimAllRewards() public {
        calculateReward(msg.sender);
        uint256 rewardAmount = stakers[msg.sender].pendingRewards;
        stakers[msg.sender].totalRewardsClaimed += rewardAmount;
        stakers[msg.sender].pendingRewards = 0;
        rewardsToken.mint(msg.sender, rewardAmount);
        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    // 解除质押
    function unstake(uint256 _tokenId) public {
        require(tokenOwner[_tokenId] == msg.sender,
            "user must be the owner of the staked nft"
        );
        calculateReward(msg.sender);
        Staker storage staker = stakers[_user];
        require(staker.pendingRewards <= 0, "Claim your rewards first");
        staker.lockPeriod[_tokenId] = 0;
        if (staker.tokenIds.length > 0) {
            for (uint256 i = 0; i < staker.tokenIds.length; i++) {
                if (staker.tokenIds[i] == _tokenId) {
                    if (staker.tokenIds.length > 1) {
                        staker.tokenIds[i] = staker.tokenIds[staker.tokenIds.length - 1];
                    }
                    staker.tokenIds.pop();
                    break;
                }
            }
        }
        stakedNFT.safeTransferFrom(address(this), msg.sender, _tokenId);
        emit UnstakedSuccess(msg.sender, _tokenId);
    }
}
