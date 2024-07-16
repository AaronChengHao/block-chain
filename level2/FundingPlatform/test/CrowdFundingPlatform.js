// 引入 ethers, upgrades
const {ethers, upgrades } = require("hardhat");
const {expect} = require("chai");

// 定义测试套件
describe("test funding platform", function(){
    let proxyContract = null;
    // 部署测试
    it("deploy", async () => {
    // 所有者地址
    const owner = await ethers.getSigners();
        // 获取合约对象
        proxyContract = await ethers.getContractFactory("CrowdFundingPlatformV2");
        proxyContract = proxyContract.attach("0xf83bA5E77bf88956f10da61F0CCe1741956c4AbE");

        // 通过 proxy 方式部署合约
        // proxyContract = await upgrades.deployProxy(proxyContract,["0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"],{initializer:"initialize"});
        // await proxyContract.waitForDeployment();
        console.log(" proxy contract address: ",proxyContract.target);

    });


    // 创建一个众筹项目
    it("create project", async () => {
        let result = null;
        let projectContract = null;

        // 测试需要多少 gas
        result = await proxyContract.createProject.estimateGas("测试项目创建1",10000,1*60*60*24);
        console.log(result);

        return

        // 调用代理合约的 create 方法
        result = await proxyContract.createProject("测试项目创建1",10000,1*60*60*24,{gasLimit:22016});
        result = await result.wait();
        expect(result);
        // console.log(result);
        // await proxyContract.closeProjects();
        // 获取众筹的项目集合
        result = await proxyContract.getProjects();
        console.log(result,result.length);
        projectAddr = result[result.length-1];
        console.log(projectAddr);
        // 发起捐款
        projectContract = await ethers.getContractFactory("Project");
        projectContract = projectContract.attach(projectAddr);

         // 确定发送的以太数量
        const amount = 100000; // 发送0.1 Ether
        txResponse = await projectContract.donate({value:amount,gasLimit:21064});
        expect(txResponse);
        // 等待区块确认
        await txResponse.wait();

        return

        // 获取已捐款记录
        txResponse =await projectContract.getDonations();
        console.log(txResponse);

        // 需要筹集资金
        txResponse =await projectContract.goalAmount();
        console.log("需要筹集资金",txResponse);

        //  当前筹集资金
        txResponse =await projectContract.currentAmount();
                // 等待区块确认
                // await txResponse.wait();
        console.log("当前筹集资金",txResponse);

        // 筹款结束时间
        txResponse =await projectContract.deadline();
        console.log("筹款结束时间",txResponse);

        // 改变筹款状态
        txResponse =await projectContract.updateProjectState();
        // 当前筹款状态
        txResponse =await projectContract.state();
        console.log("当前筹款状态",txResponse);

        // 提取金额
        txResponse =await projectContract.withdrawFunds();
            // 等待区块确认
            await txResponse.wait();
        console.log("提取金额",txResponse);
    });
});






// var Web3 = require("web3").Web3;
// // 创建web3对象
// var web3 = new Web3("http://localhost:8545");
// // // 连接到以太坊节点
// // web3.setProvider(new Web3.providers.HttpProvider("http://localhost:8545"));
// web3.eth.
// console.log(web3);