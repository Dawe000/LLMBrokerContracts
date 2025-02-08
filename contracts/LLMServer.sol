// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import "./LLMBroker.sol";
import "./LLMAgreement.sol";

/*interface ILLMBroker{
    function updateServerDetails(uint) external;
    function deleteServer
}*/

contract LLMServer {

    //address of the owning broker contract
    address private brokerAddress;

    //index of this contract in the broker market array
    uint32 private brokerIndex;

    //exact name of the model the server is running
    string public model;

    //cost of 1 token in gwei
    uint256 public tokenCost;
    
    //url of LLM Server enpoint
    string private endpoint;

    //owners wallet address
    address payable private serverOwner;

    //max concurrent users
    uint16 private maxConcurrentAgreements;

    //map of client address to agreement contracts
    mapping(address => address) public agreements;

    uint16 public currentAgreements;

    modifier onlyBroker {
        require(
            msg.sender == brokerAddress,
            "only the brokerage can call this function"
        );
        _;
    }

    modifier onlyOwner {
        require(
            msg.sender == serverOwner,
            "only the server owner can call this function"
        );
        _;
    }

    constructor(address payable _serverOwner, address _brokerAddress, uint32 _brokerIndex) {
        brokerAddress = _brokerAddress;
        brokerIndex = _brokerIndex;
        serverOwner = _serverOwner;
        maxConcurrentAgreements = 5;
        
    }

    function setupModel(string calldata _endpoint, string calldata _model, uint256 _tokenCost) external onlyOwner {

        //require no active contracts
        model = _model;
        tokenCost = _tokenCost;
        endpoint = _endpoint;

        //update server details on the broker
        LLMBroker broker = LLMBroker(brokerAddress);
        broker.updateServerDetails(brokerIndex, _model, _tokenCost);
    }

    function setmaxConcurrentAgreements (uint16 _maxConcurrentAgreements) external {
        maxConcurrentAgreements = _maxConcurrentAgreements;
    }

    function setTokenCost (uint256 _tokenCost) external {
        tokenCost = _tokenCost;
    }

    function updateIndex(uint32 newIndex) external onlyBroker {
        brokerIndex = newIndex;
    }

    function createAgreement(uint64 pubKey) external payable returns(address){
        require(currentAgreements <= maxConcurrentAgreements, "This server has its maximum number of clients");
        LLMAgreement agreement = new LLMAgreement(msg.value / tokenCost, serverOwner, payable(msg.sender), pubKey);
        
        payable(address(agreement)).transfer(msg.value);

        agreements[msg.sender] = address(agreement);
        currentAgreements += 1;

        return (address(agreement));
    }

    function endAgreement() external {
        delete agreements[msg.sender];
        currentAgreements -= 1;
    }

    function destroySelf() external onlyOwner {
        LLMBroker broker = LLMBroker(brokerAddress);
        broker.deleteServer(brokerIndex);
    }
}