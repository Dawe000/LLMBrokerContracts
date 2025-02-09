// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

//import "./LLMBroker.sol";
import "./LLMAgreement.sol";

import {ContractRegistry} from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
import {TestFtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/TestFtsoV2Interface.sol";

interface ILLMBroker {
    function updateServerDetails(uint) external;

    function updateServerDetails(
        uint32 index,
        string calldata _model,
        uint256 _inputTokenCost,
        uint256 _outputTokenCost
    ) external;

    function updateServerTokenCost(
        uint32 index,
        uint256 _inputTokenCost,
        uint256 _outputTokenCost
    ) external;

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
    uint256 private inputTokenCost;
    uint256 private outputTokenCost;
    bool public costInUSD;

    //url of LLM Server enpoint
    string public endpoint;

    //owners wallet address
    address payable private serverOwner;

    //max concurrent users
    uint16 private maxConcurrentAgreements;

    //map of client address to agreement contracts
    mapping(address => address) public agreements;

    uint16 public currentAgreements;

    TestFtsoV2Interface private ftsoV2;
    // FLR/USD feed identifier. See https://dev.flare.network/ftso/feeds for the full list.
    bytes21[] private flrFeedId;

    modifier onlyBroker() {
        require(
            msg.sender == brokerAddress,
            "only the brokerage can call this function"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == serverOwner,
            "only the server owner can call this function"
        );
        _;
    }

    constructor(
        address payable _serverOwner,
        address _brokerAddress,
        uint32 _brokerIndex
    ) {
        brokerAddress = _brokerAddress;
        brokerIndex = _brokerIndex;
        serverOwner = _serverOwner;
        maxConcurrentAgreements = 5;

        ftsoV2 = ContractRegistry.getTestFtsoV2();
        flrFeedId = [bytes21(0x01464c522f55534400000000000000000000000000)]; //constant flare test feed id
    }

    function setupModel(
        string calldata _endpoint,
        string calldata _model,
        uint256 _inputTokenCost,
        uint256 _outputTokenCost,
        bool _costInUSD
    ) external onlyOwner {
        //require no active contracts
        model = _model;
        inputTokenCost = _inputTokenCost;
        outputTokenCost = _outputTokenCost;
        endpoint = _endpoint;
        costInUSD = _costInUSD;

        //update server details on the broker
        ILLMBroker broker = ILLMBroker(brokerAddress);

        broker.updateServerDetails(
            brokerIndex,
            _model,
            getInputTokenCost(),
            getOutputTokenCost()
        );
    }

    function setmaxConcurrentAgreements(
        uint16 _maxConcurrentAgreements
    ) external onlyOwner {
        maxConcurrentAgreements = _maxConcurrentAgreements;
    }

    function setTokenCost(
        uint256 _inputTokenCost,
        uint256 _outputTokenCost,
        bool _costInUSD
    ) external onlyOwner {
        inputTokenCost = _inputTokenCost;
        outputTokenCost = _outputTokenCost;
        costInUSD = _costInUSD;
        ILLMBroker broker = ILLMBroker(brokerAddress);

        broker.updateServerTokenCost(
            brokerIndex,
            getInputTokenCost(),
            getOutputTokenCost()
        );
    }

    function updateIndex(uint32 newIndex) external onlyBroker {
        brokerIndex = newIndex;
    }

    function createAgreement(
        uint256 pubKey
    ) external payable returns (address) {
        require(
            currentAgreements <= maxConcurrentAgreements,
            "This server has its maximum number of clients"
        );

        LLMAgreement agreement;

        agreement = new LLMAgreement{value: msg.value}(
            msg.value,
            getInputTokenCost(),
            getOutputTokenCost(),
            serverOwner,
            payable(msg.sender),
            pubKey
        );

        agreements[msg.sender] = address(agreement);
        currentAgreements += 1;

        return (address(agreement));
    }

    function getAgreementPubKey(
        address clientAddress
    ) external view returns (uint256) {
        return LLMAgreement(agreements[clientAddress]).clientPubKey();
    }

    function getAgreementContract(
        address clientAddress
    ) external view returns (address) {
        return agreements[clientAddress];
    }

    function endAgreement() external {
        delete agreements[msg.sender];
        currentAgreements -= 1;
    }

    function destroySelf() external onlyOwner {
        ILLMBroker broker = ILLMBroker(brokerAddress);
        broker.deleteServer(brokerIndex);
    }

    function getInputTokenCost() public view returns (uint256) {
        if (costInUSD) {
            return USDtoFLR(inputTokenCost);
        } else {
            return inputTokenCost;
        }
    }

    function getOutputTokenCost() public view returns (uint256) {
        if (costInUSD) {
            return USDtoFLR(outputTokenCost);
        } else {
            return outputTokenCost;
        }
    }

    function USDtoFLR(uint256 usdAmt) private view returns (uint256) {
        (uint256[] memory feedValues, int8[] memory feedDecimals, ) = ftsoV2
            .getFeedsById(flrFeedId);
        return (usdAmt * feedValues[0]) / uint256(uint8(10 ^ feedDecimals[0]));
    }
}
