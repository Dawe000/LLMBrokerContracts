// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
//import "hardhat/console.sol";

import "./LLMServer.sol";

/*
interface ILLMServer {
    function model() external view returns (string memory);
    function tokenCost() external view returns (uint);
    function updateIndex(uint) external;
}*/

contract LLMBroker {
    
    struct Server {

        string model;
        uint256 inputTokenCost;
        uint256 outputTokenCost;

        //address of the server contract
        address serverContract;
    }

    Server[] public market;
    
    modifier onlyServer(uint256 index) {
        require(
            market[index].serverContract == msg.sender,
            "A server can only modify its own market listing"
        );
        _;
    }


    function createServer() external returns (address){
        LLMServer server = new LLMServer(payable(msg.sender), address(this), uint32(market.length));

        market.push(Server({
            model: "",
            inputTokenCost:uint256(2**256-1),
            outputTokenCost:uint256(2**256-1),
            serverContract:address(server)
        }));

        return address(server);
    }

    //delete an item by moving the last item into its index, then popping last item
    function deleteServer(uint32 index) external onlyServer(index) {
        market[index] = market[market.length - 1];
        market.pop();
        LLMServer server = LLMServer(market[index].serverContract);
        server.updateIndex(index);
    }

    //updates the server details in the market array by reading details from the server contract itself
    function updateServerDetails(uint32 index) external {

        LLMServer server = LLMServer(market[index].serverContract);
        market[index].model = server.model();
        market[index].inputTokenCost = server.getInputTokenCost();
        market[index].outputTokenCost = server.getOutputTokenCost();
    }

    //updates the server details with arguments when server is sender
    function updateServerDetails(uint32 index, string calldata _model, uint256 _inputTokenCost, uint256 _outputTokenCost) external onlyServer(index){

        market[index].model = _model;
        market[index].inputTokenCost = _inputTokenCost;
        market[index].outputTokenCost = _outputTokenCost;
    }


    function updateServerTokenCost(uint32 index, uint256 _inputTokenCost, uint256 _outputTokenCost) external onlyServer(index){

        market[index].inputTokenCost = _inputTokenCost;
        market[index].outputTokenCost = _outputTokenCost;
    }

    function getAllServers() external view returns (Server[] memory){
        return market;
    }
}