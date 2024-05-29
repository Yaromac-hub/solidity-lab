// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import "./GameSharing.sol";

contract GameSharingHelper is GameSharing{
    constructor(address _val) GameSharing (_val) {
    }

    function shareGame(uint256 _gameId) public ownerOf(_gameId) {
        games[_gameId].shared = true;
    }

    function reclaimGame(uint _gameId) public ownerOf(_gameId) {
        require(gameToRenter[_gameId] != address(0), "Game is not rented");
        require(games[_gameId].readyToReclaimTime <= uint32(block.timestamp + gracePeriod));
        renterGameCount[gameToRenter[_gameId]]--;
        gameToRenter[_gameId] = address(0);
    }

    function changeMaxRentTimeInHours(uint256 _gameId, uint _newMaxRentTimeInHours) public ownerOf(_gameId) {
        require(_newMaxRentTimeInHours >= 0);
        games[_gameId].maxRentTimeInHours = _newMaxRentTimeInHours;
    }

    function changeRentalFee(uint256 _gameId, uint _newfee) public ownerOf(_gameId) {
        require(_newfee >= 0);
        games[_gameId].pricePerHour = _newfee;
    }
}