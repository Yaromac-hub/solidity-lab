// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockOracleGameStoreApi is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    address allowedAddress;

    struct Game {
        string name;
        string description;
        uint32 internalId;
    }

    function getUserGameList(string memory _authToken) external pure returns (Game[] memory) {
        require(keccak256(abi.encodePacked(_authToken)) == keccak256(abi.encodePacked("secret")));
        Game[] memory games = new Game[](3);
        games[0] = Game("COD4", "Shooter", 12345);
        games[1] = Game("StarCraft", "Strategy", 23456);
        games[2] = Game("WOW", "MMORPG", 45678);
        return games;
    }

    function getGameAccessToUser (string memory _authToken, uint32 internalId) external view returns (string memory) {
        require(msg.sender == allowedAddress, "Restricted access from specific address");
        return "Access to the game has been granted for user.";
    }

    function setUpAllovedAddress(address _address) public onlyOwner {
        allowedAddress = _address;
    }
}