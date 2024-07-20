// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// 初始化限制合约
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "hardhat/console.sol";

contract StakePlatform is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using Math for uint256;

    // ************************************** 常量 **************************************
    bytes32 public constant ADMIN_ROLE = keccak256("admin_role"); // admin 角色
    bytes32 public constant UPGRADE_ROLE = keccak256("upgrade_role"); // 升级权限角色
    uint256 public constant BTC_PID = 0;

    // ************************************** DATA STRUCTURE **************************************
    // 声明质押池结构体
    struct Pool {
        // 质押代币的地址
        address stTokenAddress;
        // 质押池的权重，影响奖励分配
        uint256 poolWeight;
        // 最后一次计算奖励的区块号
        uint256 lastRewardBlock;
        // 每个代币奖励质押B2份额
        uint256 accB2PerST;
        // 池中的总质押代币量
        uint256 stTokenAmount;
        // 最小质押金额
        uint256 minDepositAmount;
        // 解除质押的锁定区块数
        uint256 unstakeLockedBlocks;
    }
    // 声明解除质押请求
    struct UnstakeRequest {
        uint256 amount;
        uint256 unlockBlocks;
    }
    // 声明用户结构体
    struct User {
        // 用户质押的代币数量
        uint256 stAmount;
        // 已分配的 B2 数量
        uint256 finishedB2;
        // 待领取的 B2 数量
        uint256 pendingB2;
        // 解质押请求列表，每个请求包含解质押数量和解锁区块
        UnstakeRequest[] requests;
    }

    // ************************************** STATE VARIABLES **************************************
    uint256 public startBlock;
    uint256 public endBlock;
    uint256 public b2PerBlock;

    // 是否暂停取款
    bool public withdrawPaused;
    bool public claimPaused;

    // 奖励代币
    IERC20 public B2;

    uint256 public totalPoolWeight;
    Pool[] public pools;

    // pool id => user address => user info
    mapping(uint256 => mapping(address => User)) public users;

    // ************************************** 事件 **************************************
    event SetB2(IERC20 indexed B2);
    event PauseWithdraw();
    event UnpauseWithdraw();
    event PauseClaim();
    event UnpauseClaim();
    event SetStartBlock(uint256 indexed startBlock);
    event SetEndBlock(uint256 indexed endBlock);
    event SetB2PerBlock(uint256 indexed b2PerBlock);
    event AddPool(
        address indexed stTokenAddress,
        uint256 indexed poolWeight,
        uint256 indexed lastRewardBlock,
        uint256 minDepositAmount,
        uint256 unstakeLockedBlocks
    );
    event UpdatePoolInfo(
        uint256 indexed poolId,
        uint256 indexed minDepositAmount,
        uint256 indexed unstakeLockedBlocks
    );
    event SetPoolWeight(
        uint256 indexed poolId,
        uint256 indexed poolWeight,
        uint256 totalPoolWeight
    );
    event UpdatePool(
        uint256 indexed poolId,
        uint256 indexed lastRewardBlock,
        uint256 totalB2
    );
    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event RequestUnstake(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount,
        uint256 indexed blockNumber
    );
    event Claim(address indexed user, uint256 indexed poolId, uint256 b2Reward);

    // ************************************** 函数修饰器 **************************************
    modifier checkPid(uint256 _pid) {
        require(_pid < pools.length, "invalid pid");
        _;
    }

    modifier whenNotClaimPaused() {
        require(!claimPaused, "claim is paused");
        _;
    }

    modifier whenNotWithdrawPaused() {
        require(!withdrawPaused, "withdraw is paused");
        _;
    }

    /**
     * 这个函数用于初始化合约的状态，包括设置 B2 代币地址、起始区块、结束区块以及每个区块的 B2 奖励
     */
    function initialize(
        IERC20 _B2,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _b2PerBlock
    ) public initializer {
        // 确保输入的区块号有效且B2代币的产出率大于0
        require(
            _startBlock <= _endBlock && _b2PerBlock > 0,
            "invalid parameters"
        );
        __AccessControl_init();
        // 访问控制初始化，监测是否初始化
        __UUPSUpgradeable_init(); // 升级控制初始化，监测是否初始化了

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // 设置默认管理员角色地址
        _grantRole(UPGRADE_ROLE, msg.sender); // 设置升级操作角色地址
        _grantRole(ADMIN_ROLE, msg.sender); // 升级管理角色地址

        setB2(_B2);

        startBlock = _startBlock;
        endBlock = _endBlock;
        b2PerBlock = _b2PerBlock; // 每个区块产生的B2代币数量
    }

    function setB2(IERC20 _b2) public onlyRole(ADMIN_ROLE) {
        B2 = _b2;
        emit SetB2(B2);
    }

    // 设置新逻辑合约地址
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADE_ROLE) {}

    // 暂停提现，只有 admin 角色才可以调用
    function pauseWithdraw() public onlyRole(ADMIN_ROLE) {
        require(!withdrawPaused, "withdraw has been already paused");
        withdrawPaused = true;
        emit PauseWithdraw();
    }

    // 解除暂停体现， 只有 admin 角色可以调用
    function unpauseWithdraw() public onlyRole(ADMIN_ROLE) {
        require(withdrawPaused, "withadraw has been already unpaused");
        withdrawPaused = false;
        emit UnpauseWithdraw();
    }

    /**
     * 索赔停止，只有 admin 角色可以调用
     */
    function pauseClaim() public onlyRole(ADMIN_ROLE) {
        require(!claimPaused, "claim has been already paused");

        claimPaused = true;

        emit PauseClaim();
    }

    /**
     * 解除索赔停止，只有admin角色可以调用
     */
    function unpauseClaim() public onlyRole(ADMIN_ROLE) {
        require(claimPaused, "claim has been already unpaused");

        claimPaused = false;

        emit UnpauseClaim();
    }

    /**
     * @notice Update staking start block. Can only be called by admin. 更新质押开始区块，只有管理员可以调用
     */
    function setStartBlock(uint256 _startBlock) public onlyRole(ADMIN_ROLE) {
        require(
            _startBlock <= endBlock,
            "start block must be smaller than end block"
        );

        startBlock = _startBlock;

        emit SetStartBlock(_startBlock);
    }

    /**
     * @notice Update staking end block. Can only be called by admin. 更新质押结束区块，只有管理员可以调用
     */
    function setEndBlock(uint256 _endBlock) public onlyRole(ADMIN_ROLE) {
        require(
            startBlock <= _endBlock,
            "start block must be smaller than end block"
        );

        endBlock = _endBlock;

        emit SetEndBlock(_endBlock);
    }

    /**
     * @notice Update the B2 reward amount per block. Can only be called by admin. 设置 B2 代币区块, 只有管理员可以调用
     */
    function setB2PerBlock(uint256 _b2PerBlock) public onlyRole(ADMIN_ROLE) {
        require(_b2PerBlock > 0, "invalid parameter");

        b2PerBlock = _b2PerBlock;

        emit SetB2PerBlock(_b2PerBlock);
    }

    // 更新全部质押池数据
    function massUpdatePools() public {
        uint256 length = pools.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    // 更新质押池
    // function updatePool(uint256 _pid) public checkPid(_pid) {
    //     Pool storage pool_ = pools[_pid]; // 从数组中获取质押池的引用

    //     // 如果当前区块号小于或者等于池最后奖励的区块，直接返回
    //     if (block.number <= pool_.lastRewardBlock) {
    //         return;
    //     }

    //     (bool success1, uint256 totalB2) = getMultiplier(
    //         pool_.lastRewardBlock,
    //         block.number
    //     ).tryMul(pool_.poolWeight);
    //     require(success1, "totalB2 mul poolWeight overflow");

    //     (success1, totalB2) = totalB2.tryDiv(totalPoolWeight);
    //     require(success1, "totalB2 div totalPoolWeight overflow");

    //     uint256 stSupply = pool_.stTokenAmount;
    //     if (stSupply > 0) {
    //         (bool success2, uint256 totalB2_) = totalB2.tryMul(1 ether);
    //         require(success2, "totalB2 mul 1 ether overflow");

    //         (success2, totalB2_) = totalB2_.tryDiv(stSupply);
    //         require(success2, "totalB2 div stSupply overflow");

    //         (bool success3, uint256 accB2PerST) = pool_.accB2PerST.tryAdd(
    //             totalB2_
    //         );
    //         require(success3, "pool accB2PerST overflow");
    //         pool_.accB2PerST = accB2PerST;
    //     }

    //     pool_.lastRewardBlock = block.number;

    //     emit UpdatePool(_pid, pool_.lastRewardBlock, totalB2);
    // }

    // function addPool(address _stTokenAddress, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakeLockedBlocks,  bool _withUpdate) public onlyRole(ADMIN_ROLE) {
    // 添加一个质押池 _stTokenAddress 质押token地址， _poolWeight 权重，_minDepositAmount 最小质押金额, unstakeLockedBlocks 解除质押的锁定区块数
    function addPool(
        address _stTokenAddress,
        uint256 _poolWeight,
        uint256 _minDepositAmount,
        uint256 _unstakeLockedBlocks,
        bool _withUpdate
    ) public onlyRole(ADMIN_ROLE) returns (uint256) {
        if (pools.length > 0) {
            require(
                _stTokenAddress != address(0x0),
                "invalid staking token addressa"
            );
        } else {
            require(
                _stTokenAddress == address(0x0),
                "invalid staking token addressas"
            );
        }
        require(_unstakeLockedBlocks > 0, "invalid withdraw locked blocks");
        require(block.number < endBlock, "Already ended");

        if (_withUpdate) {
            massUpdatePools();
        }

        // 计算奖励的开始区块号,引入区块号主要是为了计算代币质押时间，然后计算对应的奖励
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalPoolWeight = totalPoolWeight + _poolWeight;

        pools.push(
            Pool({
                stTokenAddress: _stTokenAddress,
                poolWeight: _poolWeight,
                lastRewardBlock: lastRewardBlock,
                accB2PerST: 0,
                stTokenAmount: 0,
                minDepositAmount: _minDepositAmount,
                unstakeLockedBlocks: _unstakeLockedBlocks
            })
        );

        emit AddPool(
            _stTokenAddress,
            _poolWeight,
            lastRewardBlock,
            _minDepositAmount,
            _unstakeLockedBlocks
        );
    }

    /**
     * @notice Update the given pool's weight. Can only be called by admin. 管理员权限调用
     */
    function setPoolWeight(
        uint256 _pid,
        uint256 _poolWeight,
        bool _withUpdate
    ) public onlyRole(ADMIN_ROLE) checkPid(_pid) {
        require(_poolWeight > 0, "invalid pool weight");

        if (_withUpdate) {
            massUpdatePools();
        }

        totalPoolWeight =
            totalPoolWeight -
            pools[_pid].poolWeight +
            _poolWeight;
        pools[_pid].poolWeight = _poolWeight;

        emit SetPoolWeight(_pid, _poolWeight, totalPoolWeight);
    }

    // ************************************** QUERY FUNCTION **************************************

    /**
     * @notice Get the length/amount of pool
     */
    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    /**
     * @notice Get pending B2 amount of user in pool
     */
    function pendingB2(
        uint256 _pid,
        address _user
    ) external view checkPid(_pid) returns (uint256) {
        return pendingB2ByBlockNumber(_pid, _user, block.number);
    }

    /**
     * @notice Get pending B2 amount of user by block number in pool
     */
    function pendingB2ByBlockNumber(
        uint256 _pid,
        address _user,
        uint256 _blockNumber
    ) public view checkPid(_pid) returns (uint256) {
        Pool storage pool_ = pools[_pid];
        User storage user_ = users[_pid][_user];
        uint256 accB2PerST = pool_.accB2PerST;
        uint256 stSupply = pool_.stTokenAmount;

        if (_blockNumber > pool_.lastRewardBlock && stSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool_.lastRewardBlock,
                _blockNumber
            );
            uint256 b2ForPool = (multiplier * pool_.poolWeight) /
                totalPoolWeight;
            accB2PerST = accB2PerST + (b2ForPool * (1 ether)) / stSupply;
        }

        return
            (user_.stAmount * accB2PerST) /
            (1 ether) -
            user_.finishedB2 +
            user_.pendingB2;
    }

    /**
     * @notice Get the staking amount of user
     */
    function stakingBalance(
        uint256 _pid,
        address _user
    ) external view checkPid(_pid) returns (uint256) {
        return users[_pid][_user].stAmount;
    }

    /**
     * @notice Get the withdraw amount info, including the locked unstake amount and the unlocked unstake amount
     */
    function withdrawAmount(
        uint256 _pid,
        address _user
    )
        public
        view
        checkPid(_pid)
        returns (uint256 requestAmount, uint256 pendingWithdrawAmount)
    {
        User storage user_ = users[_pid][_user];

        for (uint256 i = 0; i < user_.requests.length; i++) {
            if (user_.requests[i].unlockBlocks <= block.number) {
                pendingWithdrawAmount =
                    pendingWithdrawAmount +
                    user_.requests[i].amount;
            }
            requestAmount = requestAmount + user_.requests[i].amount;
        }
    }

    // 开始质押
    function deposit(uint256 _pid, uint256 _amount) public checkPid(_pid) {
        require(_pid != 0, "deposit not support BTC staking");
        Pool storage pool_ = pools[_pid];

        // 验证指定池中最小的质押额度
        require(
            _amount > pool_.minDepositAmount,
            "deposit amount is too small"
        );

        // 检查用户是否已授权足够的代币给合约
        uint256 allowanceAmount = IERC20(pool_.stTokenAddress).allowance(
            msg.sender,
            address(this)
        );
        require(allowanceAmount >= _amount, "allowanceAmount lack");

        IERC20(pool_.stTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
        _deposit(_pid, _amount);
    }

    /**
     * @notice 质押的私有方法
     *
     * @param _pid       池id
     * @param _amount    数量
     */
    function _deposit(uint256 _pid, uint256 _amount) internal {
        Pool storage pool_ = pools[_pid];
        User storage user_ = users[_pid][msg.sender];

        updatePool(_pid);

        if (user_.stAmount > 0) {
            // 计算奖励，每个质押的代币，奖励 accB2PerST 倍数的奖励币
            (bool success1, uint256 accST) = user_.stAmount.tryMul(
                pool_.accB2PerST
            );
            require(success1, "mul overflow");

            (success1, accST) = accST.tryDiv(1 ether);
            require(success1, "overflow");

            (bool success2, uint256 pendingB2_) = accST.trySub(
                user_.finishedB2
            );
            require(success2, "overflow");

            if (pendingB2_ > 0) {
                (bool success3, uint256 _pendingB2) = user_.pendingB2.tryAdd(
                    pendingB2_
                );
                require(success3, "overflow");
                user_.pendingB2 = _pendingB2;
            }
        }

        if (_amount > 0) {
            (bool success4, uint256 stAmount) = user_.stAmount.tryAdd(_amount);
            require(success4, "user stAmount overflow");
            user_.stAmount = stAmount;
        }

        // 累加池中的代币数
        (bool success5, uint256 stTokenAmount) = pool_.stTokenAmount.tryAdd(
            _amount
        );
        require(success5, "pool stTokenAmount overflow");
        pool_.stTokenAmount = stTokenAmount;

        // user_.finishedB2 = user_.stAmount.mulDiv(pool_.accB2PerST, 1 ether);
        (bool success6, uint256 finishedB2) = user_.stAmount.tryMul(
            pool_.accB2PerST
        );
        require(success6, "user stAmount mul accB2PerST overflow");

        (success6, finishedB2) = finishedB2.tryDiv(1 ether);
        require(success6, "finishedB2 div 1 ether overflow");

        // 已分配的奖励代币数量
        user_.finishedB2 = finishedB2;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // 更新池最后一次的奖励区块,以及accB2PerST每个质押代币累积的B2数量
    function updatePool(uint256 _pid) public checkPid(_pid) {
        Pool storage pool_ = pools[_pid];

        if (block.number <= pool_.lastRewardBlock) {
            return;
        }

        // 计算上次奖励的区块，到当前区块，奖励的代币数量
        (bool success1, uint256 totalB2) = getMultiplier(
            pool_.lastRewardBlock,
            block.number
        ).tryMul(pool_.poolWeight);

        require(success1, "totalB2 mul poolWeight overflow");

        (success1, totalB2) = totalB2.tryDiv(totalPoolWeight);
        require(success1, "totalB2 div totalPoolWeight overflow");

        uint256 stSupply = pool_.stTokenAmount;
        if (stSupply > 0) {
            (bool success2, uint256 totalB2_) = totalB2.tryMul(1 ether);
            require(success2, "totalB2 mul 1 ether overflow");

            (success2, totalB2_) = totalB2_.tryDiv(stSupply);
            require(success2, "totalB2 div stSupply overflow");

            (bool success3, uint256 accB2PerST) = pool_.accB2PerST.tryAdd(
                totalB2_
            );
            require(success3, "pool accB2PerST overflow");
            pool_.accB2PerST = accB2PerST;
        }

        pool_.lastRewardBlock = block.number;

        emit UpdatePool(_pid, pool_.lastRewardBlock, totalB2);
    }

    /**
     * @notice Return reward multiplier over given _from to _to block. [_from, _to) 它的作用是计算从区块号_from到区块号_to（不包括_to）之间的奖励倍数
     *
     * @param _from    From block number (included)
     * @param _to      To block number (exluded)
     */
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256 multiplier) {
        require(_from <= _to, "invalid block range");
        if (_from < startBlock) {
            _from = startBlock;
        }
        if (_to > endBlock) {
            _to = endBlock;
        }
        require(_from <= _to, "end block must be greater than start block");
        bool success;
        (success, multiplier) = (_to - _from).tryMul(b2PerBlock);
        require(success, "multiplier overflow");
    }
}
