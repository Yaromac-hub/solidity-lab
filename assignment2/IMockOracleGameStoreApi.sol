// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

interface IMockOracleGameStoreApi {
    struct Game {
        string name;
        string description;
        uint32 internalId;
    }

    function getUserGameList(string memory _authToken) external view returns (Game[] memory);

    function getGameAccessToUser(string memory _authToken, uint32 internalId) external view returns (string memory);
}
