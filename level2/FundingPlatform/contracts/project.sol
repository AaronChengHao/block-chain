// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 众筹项目合约
contract Project{
    
    // 定义项目状态集合枚举
    enum ProjectState{ Ongoing, Successful, Failed}
    
    // 资助结构体
    struct Donation{
        address donor;
        uint256 amount;
    }

    // 创建者
    address public creator;
    
    // 项目介绍
    string public description;

    // 需要筹集资金
    uint256 public goalAmount;

    // 截止时间
    uint256 public deadline;

    // 当前筹集资金
    uint256 public currentAmount;

    // 合约当前状态
    ProjectState public state;

    // 资金记录集合
    Donation[] public donations;

    // 资助事件
    event DonationReceived(address indexed donor, uint256 amount);
    // 项目状态改变事件
    event ProjectStateChanged(ProjectState newState);
    // 提款事件
    event FundsWithdrawn(address indexed creator,uint256 amount);
    // 退款事件
    event FundsRefunded(address indexed donor, uint256 amount);

    // 创建者校验
    modifier onlyCreator(){
        require(msg.sender == creator, "Not the project creator");
        _;
    }
    // 截止时间校验
    modifier onlyAfterDeadline(){
        require(block.timestamp < deadline, "Project is still ongoing");
        _;
    }
    // 合约初始化
    function initialize(address _creator, string memory _description, uint256 _goalAmount, uint256 _duration) public {
        creator = _creator;
        description = _description;
        goalAmount = _goalAmount;
        deadline = block.timestamp + _duration;
        state = ProjectState.Ongoing;
    }

    // 捐款
    function donate()public payable  {
        require(state == ProjectState.Ongoing,"Project is not ongoing");
        require(block.timestamp < deadline, "Peoject deadline has passed");

        donations.push(Donation({
            donor:msg.sender,
            amount:msg.value
        }));

        currentAmount += msg.value;
        
        // 触发捐款事件
        emit DonationReceived(msg.sender, msg.value);
     }

    // 提款
     function withdrawFunds()external onlyCreator onlyAfterDeadline{
        require(state == ProjectState.Successful, "Project is not successful");
        
        uint256 amount = address(this).balance;

        payable(creator).transfer(amount);

        // 触发提款事件
        emit  FundsWithdrawn(creator, amount);
     }

    // 退款
    function refund() external onlyAfterDeadline {
        require(state == ProjectState.Failed, "Project is not failed");

        uint256 totalRefund = 0;

        for (uint256 i=0; i < donations.length; i++) {
            if (donations[i].donor == msg.sender) {
                totalRefund += donations[i].amount;
                donations[i].amount = 0;
            }
        }

        require(totalRefund > 0, "no funds to refund");

        payable(msg.sender).transfer(totalRefund);

        emit FundsRefunded(msg.sender, totalRefund);

    }


    function updateProjectState()external onlyAfterDeadline {
        require(state == ProjectState.Ongoing, "Project is alredy finalized");

        if (currentAmount >= goalAmount) {
            state = ProjectState.Successful;
        } else {
            state = ProjectState.Failed;
        }

        emit ProjectStateChanged(state);
    }

    // 获取捐款记录
    function getDonations()public view returns(Donation[] memory) {
        return donations;
    }

}