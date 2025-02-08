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
        uint256 tokenCost;

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
            tokenCost:uint256(2**64-1),
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
        market[index].tokenCost = server.tokenCost();
    }

    //updates the server details with arguments when server is sender
    function updateServerDetails(uint32 index, string calldata _model, uint256 _tokenCost) external onlyServer(index){

        market[index].model = _model;
        market[index].tokenCost = _tokenCost;
    }

    function getAllServers() external view returns (Server[] memory){
        return market;
    }
}