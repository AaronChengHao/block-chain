// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./project.sol";

contract CrowdFundingPlatformV2 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    address[] public projects;

    event ProjectCreated(
        address projectAddress,
        address creator,
        string description,
        uint256 goalAmount,
        uint256 deadline
    );

    // 合约初始化
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // 创建一个众筹项目
    function createProject(
        string memory _description,
        uint256 _goalAmount,
        uint256 _duration
    ) public returns (address) {
        Project newProject = new Project();
        newProject.initialize(msg.sender, _description, _goalAmount, _duration);
        projects.push(address(newProject));

        emit ProjectCreated(
            address(newProject),
            msg.sender,
            _description,
            _goalAmount,
            block.timestamp + _duration
        );
        return address(newProject);
    }

    // 获取众筹项目集合
    function getProjects() public view returns (address[] memory) {
        return projects;
    }

    function closeProjects() public  {
        projects = new address[](0);
    }

    function getProjectCount() public view returns(uint256) {
        return projects.length;
    }
}
