// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 定义一个合约
contract IDOToken is ERC20("AXS Token", "AXS"), Ownable {
    // 定义公开的 IDO 价格，初始值为 0.1 eth
    uint256 public idoPrice = 0.1 * 10**18;

    // 定义公开的最大购买量，初始值为 100 ETH
    uint256 public maxBuyAmount = 100 * 10 * 18;

    // 定义 USDT 代币的地址
    address public usdtAddress = 0x606D35e5962EC494EAaf8FE3028ce722523486D2;

    // 定义一个映射，记录是否已经购买
    mapping(address => bool) private isBuy;

    constructor(address _owner) Ownable(_owner) {}

    // 定义一个购买代币的函数
    function buyToken(uint256 amount) public {
        // 避免多次访问全局变量，节约 gas
        address sender = msg.sender;

        // 确保用户还未购买过
        require(!isBuy[sender], "You has already buy!");

        // 确保购买量不超过最大的限制
        require(amount <= maxBuyAmount, "invalid amount");

        // 从调用者地址转移 USDT 到合约地址
        IERC20(usdtAddress).transferFrom(sender, address(this), amount);

        // 计算购买量
        uint256 buyNum = (amount / idoPrice) * 10**18;

        // 标记用户已购买
        isBuy[sender] = true;

        // 铸造新的代币给调用者
        _mint(msg.sender, buyNum);
    }

    // 定义一个仅限所有者调用的体现函数
    function withdraw() public onlyOwner {
        // 获取合约地址中的 USDT 余额
        uint256 bal = IERC20(usdtAddress).balanceOf(address(this));
        // 将 usdt 余额转移给所有者
        IERC20(usdtAddress).transfer(msg.sender,bal);
    }

}
