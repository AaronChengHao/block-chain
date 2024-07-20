const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("B2Stake", function () {
  // 部署
  describe("Deployment", function () {
    it("test1", async function () {
      const [owner] = await ethers.getSigners();
      let stakeAddress = "";
      let rewardAddress = "";
      let stakePlatformAddress = "";
      let tx = null;
      let txRes = null;
      // let result = null;
      // We don't use the fixture here because we want a different deployment
      // const latestTime = await time.latest();
      // 部署 rewardToken
      const rewardTokenContract = await ethers.getContractFactory('RewardToken');
      txRes = await rewardTokenContract.deploy();
      rewardAddress = txRes.target;

      // 部署 stakeToken
      // let stakeTokenContract = await ethers.getContractFactory('StakeToken');
      // stakeTokenContract = await stakeTokenContract.deploy();
      // stakeAddress = stakeTokenContract.target;

      const stakeTokenContract = await ethers.deployContract("StakeToken");
      stakeAddress = stakeTokenContract.target;
      console.log(rewardAddress, stakeAddress);

      const stakePlatformContract = await ethers.deployContract("StakePlatform");
      stakePlatformAddress = stakePlatformContract.target;

      // 初始化函数调用
      await stakePlatformContract.initialize(rewardAddress,1,1000,2);

      // 添加质押池
      // address _stTokenAddress,
      // uint256 _poolWeight,
      // uint256 _minDepositAmount,
      // uint256 _unstakeLockedBlocks,
      // bool _withUpdate

      // 添加第一个质押池，为了和池id匹配上
      await stakePlatformContract.addPool("0x32132132132131231", 1, 5,2,false);
      return;
      await stakePlatformContract.addPool(stakeAddress, 1, 5,2,false);
      // console.log(await stakePlatformContract.pools(0));
      // console.log(stakePlatformContract.target);


      return;
      // 给 owner mint 100000个币
      await stakeTokenContract.mint(owner,100000000);

      // 授权给质押平台合约消费token
      await stakeTokenContract.approve(stakePlatformAddress,1234);



      // 检查授权给质押平台多少个token
      let allowanceToken = await stakeTokenContract.allowance(owner, stakePlatformAddress);
      console.log(allowanceToken);

      // uint256 _pid, uint256 _amount
      txRes = await stakePlatformContract.deposit(1, 1234);
      console.log(txRes)
      // result = await result.wait()
      // // IERC20 _B2,
      // // uint256 _startBlock,
      // // uint256 _endBlock,
      // // uint256 _b2PerBlock
      // console.log(result);
      // await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
      //   "Unlock time should be in the future"
      // );
    });
  });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  });
