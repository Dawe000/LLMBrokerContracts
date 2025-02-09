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
        address owner;
    }

    Server[] public market;
    
    
    modifier onlyServer(uint256 index) {
        require(
            market[index].serverContract == msg.sender,
            "A server can only modify its own market listing"
        );
        _;
    }

    /// @param serverAddress address of newly created server
    /// @param owner address of the server owner
    event serverCreated(address indexed serverAddress, address indexed owner);

    /// @notice creates a new server owned by the message sender
    function createServer() external returns (address){
        LLMServer server = new LLMServer(payable(msg.sender), address(this), uint32(market.length));

        market.push(Server({
            model: "",
            inputTokenCost:uint256(2**256-1),
            outputTokenCost:uint256(2**256-1),
            serverContract:address(server),
            owner:msg.sender
        }));

        emit serverCreated(address(server), msg.sender);

        return address(server);
    }

    /// @notice lets a server delete itself
    /// @param index index of the server that is deleting itself
    function deleteServer(uint32 index) external onlyServer(index) {
        //delete an item by moving the last item into its index, then popping last item
        market[index] = market[market.length - 1];
        market.pop();
        LLMServer server = LLMServer(market[index].serverContract);
        server.updateIndex(index);
    }

    /// @notice update the struct of a server with fresh values from the server contract
    /// @param index index of the server to be updated
    function updateServerDetails(uint32 index) external {

        //updates the server details in the market array by reading details from the server contract itself
        LLMServer server = LLMServer(market[index].serverContract);
        market[index].model = server.model();
        market[index].inputTokenCost = server.getInputTokenCost();
        market[index].outputTokenCost = server.getOutputTokenCost();
    }

    /// @notice lets a server contract update its own struct with argument values
    /// @param index index of the server to be updated
    /// @param _model large language model that the server will use
    /// @param _inputTokenCost cost of an input token cost in wei
    /// @param _outputTokenCost cost of an output token in wei
    function updateServerDetails(uint32 index, string calldata _model, uint256 _inputTokenCost, uint256 _outputTokenCost) external onlyServer(index){

        market[index].model = _model;
        market[index].inputTokenCost = _inputTokenCost;
        market[index].outputTokenCost = _outputTokenCost;
    }

    /// @notice lets a server contract update its own struct with argument values
    /// @param index index of the server to be updated
    /// @param _inputTokenCost cost of an input token cost in wei
    /// @param _outputTokenCost cost of an output token in wei
    function updateServerTokenCost(uint32 index, uint256 _inputTokenCost, uint256 _outputTokenCost) external onlyServer(index){

        market[index].inputTokenCost = _inputTokenCost;
        market[index].outputTokenCost = _outputTokenCost;
    }

    /// @notice returns the array of servers
    function getAllServers() external view returns (Server[] memory){
        return market;
    }
}