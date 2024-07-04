// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
多签钱包的功能，合约又多个 owner，一笔交易发出后，需要多个owner确认，确认数达到最低要求数之后，才可以真正的执行。
**/
contract MultiSigWallet {
    // 状态变量
    address[] public owners;

    mapping(address => bool) public isOwner;
    uint256 public required;
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool exected;
    }
    Transaction[] public transactions;

    mapping(uint256 => mapping(address => bool)) public approved;

    // 事件
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    // receive
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // 函数修饰器
    modifier onlyOwner() {
        require(isOwner[msg.sender] == true, "noe owner");
        _;
    }
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "tx doesnt exist");
        _;
    }
    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].exected, "tx is exected");
        _;
    }

    // 构造函数
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "owners is required");
        require(_required > 0, "invalid required number");
        require(_required <= _owners.length, "invalid required number");
        for (uint256 index = 0; index < _owners.length; index++) {
            address owner = _owners[index];
            // 验证是否是无效地址
            require(owner != address(0), "invalid owner");
            // 验证是否重复
            require(!isOwner[owner], "owner is not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    // 函数
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 生成一个转账交易
    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (uint256) {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, exected: false})
        );
        uint256 txId = transactions.length - 1;
        // 触发事件日志
        emit Submit(txId);

        return txId;
    }

    // 授权指定的交易
    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        // 出发授权交易事件
        emit Approve(msg.sender, _txId);
    }

    function execute(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(getApprovalCount(_txId) >= required, "approval < required");
        Transaction storage transaction = transactions[_txId];
        transaction.exected = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "tx execute fail");
        emit Execute(_txId);
    }

    // 获取交易授权数
    function getApprovalCount(uint256 _txId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 index = 0; index < owners.length; index++) {
            if (approved[_txId][owners[index]]) {
                count += 1;
            }
        }
    }

    // 取消授权
    function revoke(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
