// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import "./LLMServer.sol";

contract LLMAgreement{
    
    uint256 remainingTokens;
    address public serverAddress;
    address payable serverOwner;
    address payable client;
    uint64 userPubKey;

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

    constructor(uint256 initialTokens, address payable _serverOwner, address payable _client, uint64 _userPubKey) {
        remainingTokens = initialTokens;
        serverAddress = msg.sender;
        serverOwner = _serverOwner;
        client = _client;
        _userPubKey = _userPubKey;
    }


    function notifyResponse(uint32 numTokens) external {
        require(msg.sender == serverOwner, "only the server owner can call this function");
        remainingTokens = remainingTokens - numTokens;
    }

    function satisfied() external onlyClient{
        serverOwner.transfer(address(this).balance);
        endAgreement();
    }

    function unsatisfied(int) external onlyClient{
        endAgreement();
        
    }

    function endAgreement() private {
        LLMServer server = LLMServer(serverAddress);
        server.endAgreement();
    } 

    function refund() external onlyServerOwner{
        client.transfer(address(this).balance);
        endAgreement();
    }


}