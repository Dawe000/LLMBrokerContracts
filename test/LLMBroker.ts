import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { string } from "hardhat/internal/core/params/argumentTypes";

describe("LLMBroker", function () {

  describe("Deployment", function () {
    it("Should init market array to empty", async function () {

      //deploy broker contract
      const broker = await hre.ethers.deployContract("LLMBroker");

      // assert that the value is correct
      expect(await broker.getAllServers()).to.deep.equal([]);
    });
  });

  describe("Managing Servers", function () {

    async function setupServersandModels(){
      
      //deploy broker contract
      const LLMBroker = await hre.ethers.deployContract("LLMBroker");
      const accounts = await hre.ethers.getSigners();

      const numServers= 5;

      for(let i = 0; i < numServers; i++){
        await (LLMBroker.connect(accounts[i + 1]) as any).createServer();
      }

      let allServers = await LLMBroker.getAllServers();
      let serverAddresses = [];

      for(let i = 0; i < numServers; i++){
        serverAddresses[i] = allServers[i][2];

        let LLMServer = await hre.ethers.getContractAt("LLMServer", serverAddresses[i]);
        await (LLMServer.connect(accounts[i + 1]) as any).setupModel("local" + String(i), "deepseek-r" + String(i), 1000n);
      }

      return { LLMBroker, accounts, serverAddresses };
    }

    it("Added server should appear in market", async function () {

      //deploy broker contract
      const LLMBroker = await hre.ethers.deployContract("LLMBroker");

      const accounts = await hre.ethers.getSigners();

      await (LLMBroker.connect(accounts[1]) as any).createServer();
      await (LLMBroker.connect(accounts[2]) as any).createServer();
      await (LLMBroker.connect(accounts[3]) as any).createServer();
      await (LLMBroker.connect(accounts[4]) as any).createServer();    

      const result = await LLMBroker.getAllServers();
      const regResult = [...result].map(innerArray => [...innerArray]);

      // assert that the value is correct
      expect(regResult).to.deep.equal([
        ['', 2n**64n-1n, '0xCafac3dD18aC6c6e92c921884f9E4176737C052c'],
        ['', 2n**64n-1n, '0x9f1ac54BEF0DD2f6f3462EA0fa94fC62300d3a8e'],
        ['', 2n**64n-1n, '0xbf9fBFf01664500A33080Da5d437028b07DFcC55'],
        ['', 2n**64n-1n, '0x93b6BDa6a0813D808d75aA42e900664Ceb868bcF']
      ]);
    });

    it("Set up model should reflect in market", async function () {

      const { LLMBroker, accounts, serverAddresses } = await loadFixture(setupServersandModels);

      let result = await LLMBroker.getAllServers();
      const regResult = [...result].map(innerArray => [...innerArray]);

      // assert that the value is correct
      expect(regResult).to.deep.equal([
        [
          'deepseek-r0',
          1000n,
          '0x75537828f2ce51be7289709686A69CbFDbB714F1'
        ],
        [
          'deepseek-r1',
          1000n,
          '0xE451980132E65465d0a498c53f0b5227326Dd73F'
        ],
        [
          'deepseek-r2',
          1000n,
          '0x5392A33F7F677f59e833FEBF4016cDDD88fF9E67'
        ],
        [
          'deepseek-r3',
          1000n,
          '0xa783CDc72e34a174CCa57a6d9a74904d0Bec05A9'
        ],
        [
          'deepseek-r4',
          1000n,
          '0xB30dAf0240261Be564Cea33260F01213c47AAa0D'
        ]
      ]);
    });
    //server deletion should reflec in market

    it("Deleted server should not appear in market", async function () {

      const { LLMBroker, accounts, serverAddresses } = await loadFixture(setupServersandModels);

      let LLMServer = await hre.ethers.getContractAt("LLMServer", serverAddresses[2]);
      await (LLMServer.connect(accounts[3])).destroySelf();

      let result = await LLMBroker.getAllServers();
      const regResult = [...result].map(innerArray => [...innerArray]);

      // assert that the value is correct
      expect(regResult).to.deep.equal([
        [
          'deepseek-r0',
          1000n,
          '0x75537828f2ce51be7289709686A69CbFDbB714F1'
        ],
        [
          'deepseek-r1',
          1000n,
          '0xE451980132E65465d0a498c53f0b5227326Dd73F'
        ],
        [
          'deepseek-r4',
          1000n,
          '0xB30dAf0240261Be564Cea33260F01213c47AAa0D'
        ],
        [
          'deepseek-r3',
          1000n,
          '0xa783CDc72e34a174CCa57a6d9a74904d0Bec05A9'
        ]
      ]);
    });
    //only server owner should be able to delete model

    it("Only server owner should be able to set model", async function () {

      const { LLMBroker, accounts, serverAddresses } = await loadFixture(setupServersandModels);

      let LLMServer = await hre.ethers.getContractAt("LLMServer", serverAddresses[2]);
      await expect(LLMServer.connect(accounts[4]).setupModel("test", "test", 1)).to.be.revertedWith("only the server owner can call this function");

    });

    it("Only server owner should be able to set model", async function () {

      const { LLMBroker, accounts, serverAddresses } = await loadFixture(setupServersandModels);

      let LLMServer = await hre.ethers.getContractAt("LLMServer", serverAddresses[2]);
      await expect(LLMServer.connect(accounts[4]).destroySelf()).to.be.revertedWith("only the server owner can call this function");

    });

    //set up model should reflect in contract
    //model can only be set up by owner

  })
});