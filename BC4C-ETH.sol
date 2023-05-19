contract BC4C {


    enum PlayerStatus {UNCONFIRMED, CONFIRMED, DEPOSIT_PAID, DEPOSIT_RETURNED}
    enum ChessPiece {KING, QUEEN, BISHOP1, BISHOP2, KNIGHT1, KNIGHT2, ROCK1, ROCK2, PAWN1, PAWN2, PAWN3, PAWN4, PAWN5, PAWN6, PAWN7, PAWN8}
    enum MoveStatus {PENDING, CONFIRMED, INVALID}

    uint public constant depositFee = 2000000000;

    mapping (uint => Game) gameList;

    struct Game {
        uint id;
        address player1Addr;
        PlayerStatus player1Status;
        address player2Addr;
        PlayerStatus player2Status;
        Move [] moves;
    }

    struct Move {
        address player;
        uint id;
        ChessPiece piece;
        uint positionX;
        uint positionY;
        bool checkmate;
        MoveStatus status;
    }

    event GameCreated (uint gameId, address counterPlayer);

    event GameOver (uint gameId);

    event GameStarted (uint gameId);

    function createNewGame(uint gameId, address counterPlayer) public {
        //another game with the same id must not exist
        require (gameList[gameId].id == 0, "Another game with the same id already exists");
        //counterplayer must not be the player himself
        require (counterPlayer != msg.sender, "Player and counterplayer cannot be the same");
        gameList[gameId].id = gameId;
        gameList[gameId].player1Addr = msg.sender;
        gameList[gameId].player1Status = PlayerStatus.CONFIRMED;
        gameList[gameId].player2Addr = counterPlayer;
        gameList[gameId].player2Status = PlayerStatus.UNCONFIRMED;    
        emit GameCreated(gameId, counterPlayer);    
    }
    
    function confirmGameCreation(uint gameId) public {
        //sender must be the counterplayer
        require (gameList[gameId].player2Addr == msg.sender, "You are not the counterplayer of this game");
        //counterplayer must have not confirmed the game yet
        require (gameList[gameId].player2Status == PlayerStatus.UNCONFIRMED, "You have already confirmed the game");
        gameList[gameId].player2Status = PlayerStatus.CONFIRMED;
    }

    function move(uint gameId, ChessPiece piece, uint posX, uint posY, bool checkmate ) public {
        //sender must be one of the players
        require(gameList[gameId].player1Addr == msg.sender || gameList[gameId].player2Addr == msg.sender, "You are not one of the players in this game");
        uint len = gameList[gameId].moves.length;
        //first move
        if (len == 0){
            //both players must have paid the deposit
            require(gameList[gameId].player1Status == PlayerStatus.DEPOSIT_PAID && gameList[gameId].player2Status == PlayerStatus.DEPOSIT_PAID, "At least one player has not paid the deposit yet");
        } else {
            //previous move must not be pending
            require(gameList[gameId].moves[len-1].status != MoveStatus.PENDING, "Previous move has not been confirmed yet");
            //previous move has been confirmed
            if (gameList[gameId].moves[len-1].status == MoveStatus.CONFIRMED){
                //previous move must have been made by the counterplayer
                require(gameList[gameId].moves[len-1].player != msg.sender, "It is not your turn");
                //previous move must not be a checkmate
                require(gameList[gameId].moves[len-1].checkmate == false, "The game is over");
            //previous move was invalid
            } else {
                //previous move must have been made by the current player
                require(gameList[gameId].moves[len-1].player == msg.sender, "It is not your turn");    
            }           
        }
        gameList[gameId].moves.push(Move(msg.sender, len, piece, posX, posY, checkmate, MoveStatus.PENDING));
    }

    function confirmMove(uint gameId) public {
        //sender must be one of the players
        require(gameList[gameId].player1Addr == msg.sender || gameList[gameId].player2Addr == msg.sender, "You are not one of the players in this game");
        uint len = gameList[gameId].moves.length;
        //current move must be pending
        require(gameList[gameId].moves[len-1].status == MoveStatus.PENDING, "Current move has already been confirmed or invalidated");
        //sender must not be the player who made the move
        require(gameList[gameId].moves[len-1].player != msg.sender, "Move must be confirmed by the other player");
        gameList[gameId].moves[len-1].status = MoveStatus.CONFIRMED;
        //checkmate confirmed
        if (gameList[gameId].moves[len-1].checkmate == true) {
            //notify game over
            emit GameOver(gameId);
        }
    }

    function invalidateMove(uint gameId) public {
        //sender must be one of the players
        require(gameList[gameId].player1Addr == msg.sender || gameList[gameId].player2Addr == msg.sender, "You are not one of the players in this game");
        uint len = gameList[gameId].moves.length;
        //current move must be pending
        require(gameList[gameId].moves[len-1].status == MoveStatus.PENDING, "current move has already been confirmed or invalidated");
        //sender must not be the player who made the move
        require(gameList[gameId].moves[len-1].player != msg.sender, "Move must be confirmed by the other player");
        gameList[gameId].moves[len-1].status = MoveStatus.INVALID;
    }

    
    function payDeposit(uint gameId) public payable {
        //sender must be one of the players
        require(gameList[gameId].player1Addr == msg.sender || gameList[gameId].player2Addr == msg.sender, "You are not one of the players in this game");
        //amount must be equal to the deposit
        require(msg.value == depositFee, "The amount must be equal to the deposit fee");
        //game must not be over
        require (gameList[gameId].player1Status != PlayerStatus.DEPOSIT_RETURNED || gameList[gameId].player2Status != PlayerStatus.DEPOSIT_RETURNED, "The game is over")
        if (gameList[gameId].player1Addr == msg.sender) {
            //player must have confirmed the game
            require (gameList[gameId].player1Status == PlayerStatus.CONFIRMED, "You have not confirmed the game yet, or you already paid the deposit");
            gameList[gameId].player1Status = PlayerStatus.DEPOSIT_PAID;
        } else {
            //player must have confirmed the game
            require (gameList[gameId].player2Status == PlayerStatus.CONFIRMED, "You have not confirmed the game yet, or you already paid the deposit");
            gameList[gameId].player2Status = PlayerStatus.DEPOSIT_PAID;
        }
    }

    function returnDeposit(uint gameId) public {
        uint len = gameList[gameId].moves.length;
        //final move must be checkmate
        require(gameList[gameId].moves[len-1].checkmate == true, "Last move must be checkmate");
        //final move must have been confirmed
        require(gameList[gameId].moves[len-1].status == MoveStatus.CONFIRMED, "Checkmate has not been confirmed yet");
        //sender must be the winner
        require(gameList[gameId].moves[len-1].player == msg.sender, "The deposit can only be returned to the winner");
        //sender must have not already claimed the deposit
        if (gameList[gameId].player1Addr == msg.sender) {
            require(gameList[gameId].player1Status != PlayerStatus.DEPOSIT_RETURNED, "The deposit has already been returned");
        } else {
            require(gameList[gameId].player2Status != PlayerStatus.DEPOSIT_RETURNED, "The deposit has already been returned");
        }
        (bool sent, bytes memory data) = payable(msg.sender).call{value: depositFee*2}("");
        require(sent, "Failed to send deposit to the winner");
        //change player status
        if (gameList[gameId].player1Addr == msg.sender) {
            gameList[gameId].player1Status = PlayerStatus.DEPOSIT_RETURNED;
        } else {
            gameList[gameId].player2Status = PlayerStatus.DEPOSIT_RETURNED;
        }
    }

    function getGame(uint gameId) public view returns (Game memory game) {
        return gameList[gameId];
    }
	
	function getLastMove(uint gameId) public view returns (Move memory lastMove) {
		uint len = gameList[gameId].moves.length;
		return gameList[gameId].moves[len-1];
	}

    
}