// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

interface ILLMServer {
    function endAgreement() external;
}

contract LLMAgreement{
    
    uint256 public remainingBalance;
    uint256 inputTokenCost;
    uint256 outputTokenCost;

    address public serverAddress;
    address payable serverOwner;
    address payable client;
    uint256 public clientPubKey;

    modifier onlyClient {
        require(
            msg.sender == client,
            "only the client can call this function"
        );
        _;
    }

    modifier onlyServerOwner {
        require(
            msg.sender == client,
            "only the server owner can call this function"
        );
        _;
    }

    constructor(uint256 _initialBalance, uint256 _inputTokenCost, uint256 _outputTokenCost, address payable _serverOwner, address payable _client, uint256 _clientPubKey) payable {
        remainingBalance = _initialBalance;
        inputTokenCost = _inputTokenCost;
        outputTokenCost = _outputTokenCost;
        
        serverAddress = msg.sender;
        serverOwner = _serverOwner;
        client = _client;
        clientPubKey = _clientPubKey;
    }


    function notifyResponse(uint32 numInputTokens, uint32 numOutputTokens) external {
        require(msg.sender == serverOwner, "only the server owner can call this function");
        remainingBalance = remainingBalance - (numInputTokens * inputTokenCost + numOutputTokens * outputTokenCost);
    }

    function satisfied() external onlyClient{
        client.transfer(remainingBalance);
        serverOwner.transfer(address(this).balance);
        endAgreement();
    }

    function unsatisfied() external onlyClient{
        client.transfer(remainingBalance);
        //serverOwner.transfer(address(this).balance);
        endAgreement();    
    }

    function endAgreement() private {
        ILLMServer server = ILLMServer(serverAddress);
        server.endAgreement();
    } 

    function refund() external onlyServerOwner{
        client.transfer(address(this).balance);
        endAgreement();
    }


}