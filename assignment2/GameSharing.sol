// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import "./IMockOracleGameStoreApi.sol";

contract GameSharing {

    IMockOracleGameStoreApi public mockApi;

    constructor(address oracleAddress) {
        mockApi = IMockOracleGameStoreApi(oracleAddress);
    }

    event NewGame(uint gameId, string name, string description);
    event GameRented(uint gameId);

    struct Game {
        string name;
        string description;
        uint32 internalId;
        bool shared;
        uint pricePerHour; // Price in wei
        uint maxRentTimeInHours;
        uint32 readyToReclaimTime;
    }

    Game[] public games;

    mapping(uint => address) public gameToOwner;
    mapping(uint => address) public gameToRenter;
    mapping (address => uint) ownerGameCount;
    mapping (address => uint) renterGameCount;

    uint gracePeriod = 300;
    
    modifier ownerOf(uint _gameId) {
        require(msg.sender == gameToOwner[_gameId], "The action can be performed only by the game Owner!");
        _;
    }

    function addGame(string memory _name, string memory _description, uint32 _internalId) private {
        games.push(Game(_name, _description, _internalId, false, 10000, 8, uint32(block.timestamp)));
        uint newGameId = games.length - 1;
        gameToOwner[newGameId] = msg.sender;
        gameToRenter[newGameId] = address(0);
        emit NewGame(newGameId, _name, _description);
    }

    function addGameLibrary(string memory _authToken) public {
        IMockOracleGameStoreApi.Game[] memory gameLibrary = mockApi.getUserGameList(_authToken);
        Game[] memory gamesOfUser = getGamesByOwner(msg.sender);

        for (uint256 i = 0; i < gameLibrary.length; i++) {
            bool gameAlreadyAdded = false;
            for (uint j = 0; j < gamesOfUser.length; j++) {
                if (gamesOfUser[j].internalId == gameLibrary[i].internalId) {
                    gameAlreadyAdded = true;
                    break;
                }
            }
            if (!gameAlreadyAdded) {
                addGame(gameLibrary[i].name, gameLibrary[i].description, gameLibrary[i].internalId);
                ownerGameCount[msg.sender]++;
            }
        }
    }

    function shareGame(uint256 _gameId) public ownerOf(_gameId) {
        games[_gameId].shared = true;
    }

    function changeMaxRentTimeInHours(uint256 _gameId, uint _newMaxRentTimeInHours) public ownerOf(_gameId) {
        require(_newMaxRentTimeInHours >= 0);
        games[_gameId].maxRentTimeInHours = _newMaxRentTimeInHours;
    }

    function changeRentalFee(uint256 _gameId, uint _newfee) public ownerOf(_gameId) {
        require(_newfee >= 0);
        games[_gameId].pricePerHour = _newfee;
    }

    function rentGame(string memory _authToken, uint _gameId, uint _rentTime) public payable returns(string memory){
        require(games[_gameId].shared, "Game is not shared");
        require(gameToRenter[_gameId] == address(0), "Game already rented");
        require(msg.value >= _rentTime*games[_gameId].pricePerHour, "fee is less");
        require(_rentTime <= games[_gameId].maxRentTimeInHours, "Max rent time value exceeded");

        string memory jwtToken = mockApi.getGameAccessToUser(_authToken, games[_gameId].internalId);
        require(keccak256(abi.encodePacked(jwtToken)) != keccak256(abi.encodePacked("")));
        (bool sent,) = gameToOwner[_gameId].call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        gameToRenter[_gameId] = msg.sender;
        games[_gameId].readyToReclaimTime = uint32(block.timestamp +  _rentTime * 3600);
        renterGameCount[msg.sender]++;
        emit GameRented(_gameId);
        return jwtToken;
    }

    function reclaimGame(uint _gameId) public ownerOf(_gameId) {
        require(gameToRenter[_gameId] != address(0), "Game is not rented");
        require(games[_gameId].readyToReclaimTime <= uint32(block.timestamp + gracePeriod));
        renterGameCount[msg.sender]--;
        gameToRenter[_gameId] = address(0);
    }

    function getGamesByOwner(address _owner) public view returns(Game[] memory) {
        Game[] memory result = new Game[](ownerGameCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < games.length; i++) {
            if (gameToOwner[i] == _owner) {
                result[counter] = games[i];
                counter++;
            }
        }
        return result;
    }

    function getGamesByRenter(address _renter) external view returns(Game[] memory) {
        Game[] memory result = new Game[](renterGameCount[_renter]);
        uint counter = 0;
        for (uint i = 0; i < games.length; i++) {
            if (gameToRenter[i] == _renter) {
                result[counter] = games[i];
                counter++;
            }
        }
        return result;
    }
}
