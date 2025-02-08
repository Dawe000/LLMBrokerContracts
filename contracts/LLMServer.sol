// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

//import "./LLMBroker.sol";
import "./LLMAgreement.sol";

interface ILLMBroker{
    function updateServerDetails(uint) external;
    function updateServerDetails(uint32 index, string calldata _model, uint256 _inputTokenCost, uint256 _outputTokenCost) external;
    function updateServerTokenCost(uint32 index, uint256 _inputTokenCost, uint256 _outputTokenCost) external;
    function deleteServer(uint32 index) external;
}

contract LLMServer {

    //address of the owning broker contract
    address private brokerAddress;

    //index of this contract in the broker market array
    uint32 private brokerIndex;

    //exact name of the model the server is running
    string public model;

    //cost of 1 token in gwei
    uint256 public inputTokenCost;
    uint256 public outputTokenCost;
    
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

    function setupModel(string calldata _endpoint, string calldata _model, uint256 _inputTokenCost, uint256 _outputTokenCost) external onlyOwner {

        //require no active contracts
        model = _model;
        inputTokenCost = _inputTokenCost;
        outputTokenCost = _outputTokenCost;
        endpoint = _endpoint;

        //update server details on the broker
        ILLMBroker broker = ILLMBroker(brokerAddress);
        broker.updateServerDetails(brokerIndex, _model, _inputTokenCost, _outputTokenCost);
    }

    function setmaxConcurrentAgreements (uint16 _maxConcurrentAgreements) external onlyOwner{
        maxConcurrentAgreements = _maxConcurrentAgreements;
    }

    function setTokenCost (uint256 _inputTokenCost, uint256 _outputTokenCost) external onlyOwner{
        inputTokenCost = _inputTokenCost;
        outputTokenCost = _outputTokenCost;
        ILLMBroker broker = ILLMBroker(brokerAddress);
        broker.updateServerTokenCost(brokerIndex, _inputTokenCost, _outputTokenCost);
    }

    function updateIndex(uint32 newIndex) external onlyBroker {
        brokerIndex = newIndex;
    }

    function createAgreement(uint64 pubKey) external payable returns(address){
        require(currentAgreements <= maxConcurrentAgreements, "This server has its maximum number of clients");
        LLMAgreement agreement = new LLMAgreement(msg.value, inputTokenCost, outputTokenCost, serverOwner, payable(msg.sender), pubKey);
        
        payable(address(agreement)).transfer(msg.value);

        agreements[msg.sender] = address(agreement);
        currentAgreements += 1;

        return (address(agreement));
    }

    function getAgreementPubKey(address clientAddress) external view returns(uint64){
        return LLMAgreement(agreements[clientAddress]).clientPubKey();
    }

    function endAgreement() external {
        delete agreements[msg.sender];
        currentAgreements -= 1;
    }

    function destroySelf() external onlyOwner {
        ILLMBroker broker = ILLMBroker(brokerAddress);
        broker.deleteServer(brokerIndex);
    }
}