pragma solidity ^0.5.3;
pragma experimental ABIEncoderV2;

contract ShitouJiandaoBu {
    
    address payable owner;
    uint deposit = 0;
    uint numberOfGames = 0;
    uint[] activeGames;
    mapping(uint=>Game) gameList;
    
    event StartNewGame(uint gameId);
    event WaitForReveal(uint gameId);
    event GameEnd(uint gameId);
    event GameWinner(uint winner);
    event DepositAmount(uint);
    
    struct Game {
        address payable player1;
        address payable player2;
        
        /*
            1: winner is player1
            2: wineer is player2
            3: tie
            4: player1 not willing to reveal
        */
        uint winner;
        
        /*
            1: player1 create the game
            2: waiting for player1 reveal
            3: game finished
        */
        uint gameState;
        
        //the hash of player1's choice and salt
        bytes32 player1Hash;
        
        /*
            1: rock
            2: paper
            3: scissors
        */
        uint player2Choice;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyPlayer1(uint _gameId) {
        Game memory game = gameList[_gameId];
        require(game.player1 == msg.sender);
        _;
    }
    
    modifier onlyPlayer2(uint _gameId) {
        Game memory game = gameList[_gameId];
        require(game.player2 == msg.sender);
        _;
    }
    
    modifier notPlayer1(uint _gameId) {
        Game memory game = gameList[_gameId];
        require(game.player1 != msg.sender);
        _;
    }
    
    constructor() public{
        owner = msg.sender;
    }
    
    // function checkDeposit() public payable onlyOwner returns(uint) {
    //     emit DepositAmount(deposit);
    //     return deposit;
    // }
    
    // function checkWei() public view onlyOwner returns(uint){
    //     return address(this).balance;
    // }
    
    function startNewGame(bytes32 _hash) public payable returns(uint){
        require(msg.value == 11);
        deposit = deposit + 1;
        
        Game memory newGame = Game({
            player1 : msg.sender,
            player2 : address(0),
            winner : 0,
            gameState : 1,
            player1Hash : _hash,
            player2Choice : 0
        });
        
        uint gameId = numberOfGames;
        gameList[gameId] = newGame;
        numberOfGames = numberOfGames + 1;
        activeGames.push(gameId);
        emit StartNewGame(gameId);
        return gameId;
    }
    
    function getHash(uint _choice, string memory _salt) public pure returns(bytes32) {
        return sha256(abi.encodePacked(_choice, _salt));
    }
    
    function getActiveGmaes() public view returns(uint[] memory) {
        return activeGames;
    }
    
    function joinGame(uint _gameId, uint _choice) public payable notPlayer1(_gameId){
        require(msg.value == 10);
        require(_choice == 1 || _choice == 2 || _choice == 3);
        Game storage game = gameList[_gameId];
        require(game.player1 != address(0));
        require(game.gameState == 1);
        game.player2 = msg.sender;
        game.player2Choice = _choice;
        game.gameState = 2;
        emit WaitForReveal(_gameId);
    }
    
    function checkWinner(uint _choice1, uint _choice2) private view returns(uint) {
        uint result;
        if (_choice1 == _choice2) {
            result = 3;
        }
        else if (_choice1 == 1) {
            // rock vs paper lose
            if (_choice2 == 2) {
                result = 2;
            }
            //rock vs scissors win
            else {
                result = 1;
            }
        }
        else if (_choice1 == 2) {
            //paper vs rock win
            if (_choice2 == 1) {
                result = 1;
            }
            //paper vs scissors lose
            else {
                result = 2;
            }
        }
        else if (_choice1 == 3) {
            //scissors vs rock lose
            if (_choice2 == 1) {
                result = 2;
            }
            //sizeof vs paper win
            else {
                result = 1;
            }
        }
        return result;
    }
    
    function reveal(uint _gameId, uint _choice, string memory _salt) public payable onlyPlayer1(_gameId) {
        Game storage game = gameList[_gameId];
        require(game.gameState == 2);
        require(_choice == 1 || _choice == 2 || _choice == 3);
        require(getHash(_choice, _salt) == game.player1Hash);
        uint tmpWinner = checkWinner(_choice, game.player2Choice);
        if (tmpWinner == 3) {
            game.player1.transfer(11);
            game.player2.transfer(10);
        }
        else if (tmpWinner == 1) {
            game.player1.transfer(21);
        }
        else if (tmpWinner == 2) {
            game.player1.transfer(1);
            game.player2.transfer(20);
        }
        game.winner = tmpWinner;
        game.gameState = 3;
        deposit = deposit - 1;
        deleteActive(_gameId);
        emit GameEnd(_gameId);
        emit GameWinner(tmpWinner);
    }
    
    function withdraw(uint _gameId) public payable onlyPlayer2(_gameId) {
        Game storage game = gameList[_gameId];
        require(game.gameState == 2);
        game.gameState = 1;
        game.player2Choice = 0;
        game.player2 = address(0);
        msg.sender.transfer(10);
        emit WaitForReveal(_gameId);
    }
    
    function unwillingReveal(uint _gameId) public payable onlyPlayer1(_gameId) {
        Game storage game = gameList[_gameId];
        require(game.gameState == 1 || game.gameState == 2);
        if (game.gameState == 1) {
            game.player1.transfer(10);
        }
        else {
            game.player1.transfer(10);
            game.player2.transfer(10);
        }
        game.gameState = 3;
        game.winner = 4;
        deleteActive(_gameId);
        emit GameEnd(_gameId);
        emit GameWinner(4);
    }
    
    function deleteActive(uint _gameId) private {
        uint index;
        for(index = 0; index < activeGames.length; index++) {
            if (activeGames[index] == _gameId) {
                delete activeGames[index];
                break;
            }
        }
        if (index == activeGames.length) return;
        for (uint j = index; j<activeGames.length-1; j++){
            activeGames[j] = activeGames[j+1];
        }
        delete activeGames[activeGames.length-1];
        activeGames.length--;
    }
    
    function getGameState(uint _gameId) public view returns(uint gameState) {
        return gameList[_gameId].gameState;
    }
    
    function getWinner(uint _gameId) public view returns(uint winner) {
        return gameList[_gameId].winner;
    }
    
}
