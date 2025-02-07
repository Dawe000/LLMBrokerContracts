// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
import "hardhat/console.sol";

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
        uint64 tokenCost;

        //address of the server contract
        address serverContract;
    }

    Server[] public market;
    
    modifier onlyServer(uint64 index) {
        console.log("0");
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
            tokenCost:uint64(2**64-1),
            serverContract:address(server)
        }));

        return address(server);
    }

    //delete an item by moving the last item into its index, then popping last item
    function deleteServer(uint32 index) external onlyServer(index) {
        console.log("1");
        market[index] = market[market.length];
        console.log("2");
        market.pop();
        console.log("3");
        LLMServer server = LLMServer(market[index].serverContract);
        console.log("4");
        server.updateIndex(index);
        console.log("5");
    }

    //updates the server details in the market array by reading details from the server contract itself
    function updateServerDetails(uint32 index) external {

        LLMServer server = LLMServer(market[index].serverContract);
        market[index].model = server.model();
        market[index].tokenCost = server.tokenCost();
    }

    //updates the server details with arguments when server is sender
    function updateServerDetails(uint32 index, string calldata _model, uint64 _tokenCost) external onlyServer(index){

        market[index].model = _model;
        market[index].tokenCost = _tokenCost;
    }

    function getAllServers() external view returns (Server[] memory){
        return market;
    }
}