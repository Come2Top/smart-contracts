// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {IERC20} from "../interfaces/IERC20.sol";
import {IFraxtalL1Block} from "../interfaces/IFraxtalL1Block.sol";
import {IBeefyVault} from "../interfaces/IBeefyVault.sol";
import {ICurveStableNG} from "../interfaces/ICurveStableNG.sol";

import {GameStorageLib, GameStorage, Status, GameData, Offer, OfferorData, PlayerGameBalance, StratConfig} from "../libraries/GameStorageLib.sol";
import {GameConstantsLib} from "../libraries/GameConstantsLib.sol";
import {GameImmutablesLib} from "../libraries/GameImmutablesLib.sol";
import {GameStatusLib} from "../libraries/GameStatusLib.sol";
import {GameTicketsLib} from "../libraries/GameTicketsLib.sol";
import {GameOffersLib} from "../libraries/GameOffersLib.sol";
import {CurveMooLib} from "../libraries/CurveMooLib.sol";

contract GameActionsFacet {
    using CurveMooLib for uint256;

    /********************************\
    |-*-*-*-*-*   EVENTS   *-*-*-*-*-|
    \********************************/
    event TicketsSold(address indexed buyer, bytes ticketIDs);

    event GameStarted(
        uint256 indexed gameID,
        uint256 indexed startedBlockNo,
        uint256 amount
    );

    event GameUpdated(
        uint256 indexed gameID,
        address indexed winner,
        uint256 amount,
        uint256 ticketID
    );

    event OfferMade(
        address indexed maker,
        uint256 indexed ticketID,
        uint256 amount,
        address lastOfferor
    );

    event OfferAccepted(
        address indexed newOwner,
        uint256 indexed ticketID,
        uint256 amount,
        address lastOwner
    );

    event GameFinished(
        uint256 indexed gameID,
        address[2] winners,
        uint256[2] amounts,
        uint256[2] ticketIDs
    );

    event Claimed(
        uint256 indexed gameID,
        address indexed player,
        uint256 amount,
        int256 profit
    );

    event StaleOffersTookBack(address indexed maker, uint256 amount);

    /********************************\
    |-*-*-*-*-*   ERRORS   *-*-*-*-*-|
    \********************************/
    error ONLY_EOA();
    error ONLY_TICKET_OWNER(uint256 ticketID);
    error ONLY_CLAIMABLE_MODE(Status stat);
    error ONLY_UNPAUSED_OR_TICKET_SALE_MODE(bool isPaused);
    error ONLY_HIGHER_THAN_CURRENT_TICKET_VALUE(
        uint256 offer,
        uint256 ticketValue
    );
    error ONLY_HIGHER_THAN_CURRENT_OFFER_VALUE(
        uint256 offer,
        uint256 lastOfferValue
    );
    error CHECK_TICKETS_LENGTH(uint256 ticketLength);
    error SELECTED_TICKETS_SOLDOUT_BEFORE();
    error PARTICIPATED_BEFORE();
    error NO_AMOUNT_TO_CLAIM();
    error NO_AMOUNT_TO_REFUND();
    error WAIT_FOR_NEXT_MATCH();
    error WAIT_FOR_NEXT_WAVE();

    /*******************************\
    |-*-*-*-*   MODIFIERS   *-*-*-*-|
    \*******************************/
    modifier onlyEOA() {
        if (msg.sender != tx.origin) revert ONLY_EOA();

        _;
    }

    /********************************\
    |-*-*-*-*   GAME-LOGIC   *-*-*-*-|
    \********************************/
    /**
        @notice Players can buy tickets to join the game.
        @dev Manages the ticket allocation, ownership, and purchase process.
            Also ensures that the maximum number of tickets specified by {maxTicketsPerGame}
                and the ticket price set by {ticketPrice} are adhered to.
            When all tickets are sold out, it will lock them for {L1_BLOCK_LOCK_TIME} time duration
                and invest them in a yield farming protocol (stables) such as Beefy.
            The player joining the game, must be an externally owned account (EOA).
        @param ticketIDs The ticket IDs that players want to buy for a game.
    */
    function ticketSaleOperation(uint8[] calldata ticketIDs) external onlyEOA {
        GameStorage storage gs = GameStorageLib.gameStorage();

        uint256 gameID = gs.currentGameID;
        uint256 neededToken = gs.ticketPrice;
        uint256 totalTickets = ticketIDs.length;
        uint256 ticketLimit = gs.maxTicketsPerGame;
        bytes memory realTickets;
        GameData storage GD;

        (Status stat, , , ) = GameStatusLib.gameUpdate(gameID);
        if (uint256(stat) > 2) {
            unchecked {
                gameID++;
                gs.currentGameID++;
            }

            GD = gs.gameData[gameID];
            GD.tickets = GameConstantsLib.BYTE_TICKETS();
        } else GD = gs.gameData[gameID];

        uint256 remainingTickets = GameConstantsLib.MAX_PARTIES() -
            GD.soldTickets;
        bytes memory tickets = GD.tickets;

        if (gs.pause && GD.soldTickets == 0)
            revert ONLY_UNPAUSED_OR_TICKET_SALE_MODE(gs.pause);

        if (totalTickets == 0 || totalTickets > ticketLimit)
            revert CHECK_TICKETS_LENGTH(totalTickets);

        if (GD.startedL1Block != 0) revert WAIT_FOR_NEXT_MATCH();

        if (
            totalTickets + gs.totalPlayerTickets[gameID][msg.sender] >
            ticketLimit
        ) revert PARTICIPATED_BEFORE();

        for (uint256 i; i < totalTickets; ) {
            if (ticketIDs[i] == 0) {
                if (tickets[0] != 0xff) {
                    tickets[0] = 0xff;
                    realTickets = abi.encodePacked(realTickets, bytes1(0x00));
                    gs.tempTicketOwnership[gameID][0] = msg.sender;
                }
            } else {
                if (tickets[ticketIDs[i]] != 0x00) {
                    tickets[ticketIDs[i]] = 0x00;
                    realTickets = abi.encodePacked(
                        realTickets,
                        bytes1(ticketIDs[i])
                    );
                    gs.tempTicketOwnership[gameID][ticketIDs[i]] = msg.sender;
                }
            }

            unchecked {
                i++;
            }
        }

        totalTickets = realTickets.length;

        if (totalTickets == 0) revert SELECTED_TICKETS_SOLDOUT_BEFORE();

        _transferFromHelper(
            msg.sender,
            GameImmutablesLib.THIS(),
            (totalTickets * neededToken)
        );

        emit TicketsSold(msg.sender, realTickets);

        if (totalTickets == remainingTickets) {
            uint64 currentL1Block = GameImmutablesLib
                .FRAXTAL_L1_BLOCK()
                .number();
            IBeefyVault beefyVault = gs
                .gameStratConfig[gs.currentGameStrat]
                .beefyVault;
            ICurveStableNG curveStableNG = gs
                .gameStratConfig[gs.currentGameStrat]
                .curveStableNG;

            GD.prngPeriod = uint112(gs.prngPeriod);
            GD.startedL1Block = currentL1Block;
            GD.tickets = GameConstantsLib.BYTE_TICKETS();
            GD.chosenConfig = gs.currentGameStrat;
            GD.initialFraxBalance =
                GameConstantsLib.MAX_PARTIES() *
                neededToken;
            GD.virtualFraxBalance =
                GameConstantsLib.MAX_PARTIES() *
                neededToken;

            uint256 beforeBalance = beefyVault.balanceOf(
                GameImmutablesLib.THIS()
            );

            (
                (GameConstantsLib.MAX_PARTIES() * neededToken).mintLPT(
                    gs.gameStratConfig[gs.currentGameStrat].fraxTokenPosition,
                    curveStableNG
                )
            ).depositLPT(beefyVault);

            GD.mooTokenBalance =
                beefyVault.balanceOf(GameImmutablesLib.THIS()) -
                beforeBalance;
            GD.mooShare = beefyVault.getPricePerFullShare();

            emit GameStarted(
                gameID,
                currentL1Block,
                GameConstantsLib.MAX_PARTIES() * neededToken
            );
        } else {
            GD.tickets = tickets;
            unchecked {
                GD.soldTickets += uint8(totalTickets);
            }
        }

        unchecked {
            gs.totalPlayerTickets[gameID][msg.sender] += uint8(totalTickets);
            gs
            .playerBalanceData[gameID][msg.sender]
                .initialFraxBalance += uint120(totalTickets * neededToken);
        }

        if (
            gs.playerRecentGames[msg.sender].length == 0 ||
            gs.playerRecentGames[msg.sender][
                gs.playerRecentGames[msg.sender].length - 1
            ] !=
            gameID
        ) gs.playerRecentGames[msg.sender].push(gameID);
    }

    /**
        @notice Automatically, it saves the winning amount for the player
            and in the future, he/she will have the ability
            to claim the profit from the saved winning amount.
        @dev Automatically:
                If there is an offer for the currently winning ticket
                    the player accepts the offer and grants ownership of the currently winning ticket
                    to the offering player, and in the future, after the end of the {L1_BLOCK_LOCK_TIME} period
                    the amount of the accepted offer in terms of token {FRAX}
                    allows the player of the former owner to claim the resulting profit.
                Otherwise, if there is no offer, the owner's winning ticket will be removed
                    and he/she will be allowed to claim the interest of the winning amount
                    after the {L1_BLOCK_LOCK_TIME} time has passed.
        @param ticketID The ID of the ticket for which the offer is being accepted.
    */
    function winnerOperation(uint8 ticketID) external {
        GameStorage storage gs = GameStorageLib.gameStorage();

        (
            Status stat,
            int256 eligibleToSell,
            uint256 currentWave,
            bytes memory tickets
        ) = GameStatusLib.gameUpdate(gs.currentGameID);

        GameStatusLib.onlyOperational(currentWave, stat);
        uint8 index = GameTicketsLib.onlyWinnerTicket(tickets, ticketID);

        uint256 plus10PCT = GameTicketsLib.ticketValue(
            tickets.length,
            gs.currentGameID
        );
        plus10PCT +=
            (plus10PCT * GameConstantsLib.MIN_TICKET_VALUE_OFFER()) /
            GameConstantsLib.BASIS();

        if (
            gs.offer[gs.currentGameID][ticketID].amount >= plus10PCT &&
            gs.offer[gs.currentGameID][ticketID].maker !=
            GameConstantsLib.ZERO_ADDRESS()
        ) {
            Offer memory O = gs.offer[gs.currentGameID][ticketID];
            if (
                msg.sender != gs.tempTicketOwnership[gs.currentGameID][ticketID]
            ) revert ONLY_TICKET_OWNER(ticketID);

            delete gs.offer[gs.currentGameID][ticketID].maker;

            unchecked {
                gs.offerorData[O.maker].latestGameIDoffersValue -= O.amount;
                gs.offerorData[O.maker].totalOffersValue -= O.amount;
                gs.totalPlayerTickets[gs.currentGameID][msg.sender]--;
                gs.totalPlayerTickets[gs.currentGameID][O.maker]++;
            }

            gs.tempTicketOwnership[gs.currentGameID][ticketID] = O.maker;

            uint256 ticketValue_ = GameTicketsLib.ticketValue(
                tickets.length,
                gs.currentGameID
            );
            uint256 halfOfOfferProfit = (O.amount - ticketValue_) / 2;

            unchecked {
                gs.gameData[gs.currentGameID].initialFraxBalance += O.amount;
                gs
                    .gameData[gs.currentGameID]
                    .loanedFraxBalance += (ticketValue_ + halfOfOfferProfit);
                gs.gameData[gs.currentGameID].virtualFraxBalance +=
                    O.amount -
                    (ticketValue_ + halfOfOfferProfit);

                gs
                .playerBalanceData[gs.currentGameID][O.maker]
                    .initialFraxBalance += uint120(O.amount);
                gs
                .playerBalanceData[gs.currentGameID][msg.sender]
                    .loanedFraxBalance += uint120(
                    ticketValue_ + halfOfOfferProfit
                );
            }

            _transferFromHelper(
                GameImmutablesLib.TREASURY(),
                GameImmutablesLib.THIS(),
                O.amount
            );

            uint256 chosenConfig = gs.gameData[gs.currentGameID].chosenConfig;
            IBeefyVault beefyVault = gs
                .gameStratConfig[chosenConfig]
                .beefyVault;

            uint256 beforeBalance = beefyVault.balanceOf(
                GameImmutablesLib.THIS()
            );

            (
                uint256(O.amount).mintLPT(
                    gs.gameStratConfig[chosenConfig].fraxTokenPosition,
                    gs.gameStratConfig[chosenConfig].curveStableNG
                )
            ).depositLPT(beefyVault);

            gs.gameData[gs.currentGameID].rewardedMoo +=
                ((gs.gameData[gs.currentGameID].mooTokenBalance *
                    beefyVault.getPricePerFullShare()) / 1e18) -
                ((gs.gameData[gs.currentGameID].mooTokenBalance *
                    gs.gameData[gs.currentGameID].mooShare) / 1e18);

            unchecked {
                gs.gameData[gs.currentGameID].mooTokenBalance +=
                    beefyVault.balanceOf(GameImmutablesLib.THIS()) -
                    beforeBalance;
            }

            gs.gameData[gs.currentGameID].mooShare = beefyVault
                .getPricePerFullShare();

            emit OfferAccepted(
                O.maker,
                ticketID,
                ticketValue_ + halfOfOfferProfit,
                msg.sender
            );

            if (
                gs.playerRecentGames[O.maker].length == 0 ||
                gs.playerRecentGames[O.maker][
                    gs.playerRecentGames[O.maker].length - 1
                ] !=
                gs.currentGameID
            ) gs.playerRecentGames[O.maker].push(gs.currentGameID);

            return;
        }

        if (eligibleToSell == int8(0)) revert WAIT_FOR_NEXT_WAVE();

        uint256 gameID = gs.currentGameID;

        uint256 virtualFraxBalance = gs.gameData[gameID].virtualFraxBalance;

        if (tickets.length == 2) {
            gs.gameData[gameID].tickets = tickets;
            gs.gameData[gameID].eligibleToSell = -1;

            if (msg.sender != gs.tempTicketOwnership[gameID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            address winner1 = gs.tempTicketOwnership[gameID][uint8(tickets[0])];
            address winner2 = gs.tempTicketOwnership[gameID][uint8(tickets[1])];
            uint256 winner1Amount = virtualFraxBalance / 2;

            delete gs.gameData[gameID].virtualFraxBalance;
            delete gs.totalPlayerTickets[gameID][winner1];
            delete gs.totalPlayerTickets[gameID][winner2];

            unchecked {
                gs.gameData[gameID].loanedFraxBalance += virtualFraxBalance;
                gs
                .playerBalanceData[gameID][winner1]
                    .loanedFraxBalance += uint120(winner1Amount);
                gs
                .playerBalanceData[gameID][winner2]
                    .loanedFraxBalance += uint120(
                    virtualFraxBalance - winner1Amount
                );
            }

            emit GameFinished(
                gameID,
                [winner1, winner2],
                [winner1Amount, virtualFraxBalance - winner1Amount],
                [uint256(uint8(tickets[0])), uint256(uint8(tickets[1]))]
            );
        } else {
            if (msg.sender != gs.tempTicketOwnership[gameID][ticketID])
                revert ONLY_TICKET_OWNER(ticketID);

            delete gs.tempTicketOwnership[gameID][ticketID];

            gs.totalPlayerTickets[gameID][msg.sender]--;

            gs.gameData[gameID].tickets = GameTicketsLib.deleteIndex(
                index,
                tickets
            );
            gs.gameData[gameID].eligibleToSell = int8(eligibleToSell) - 1;

            if (gs.gameData[gameID].updatedWave != currentWave)
                gs.gameData[gameID].updatedWave = uint8(currentWave);

            uint256 idealWinnerPrize = virtualFraxBalance / tickets.length;

            unchecked {
                gs.gameData[gameID].loanedFraxBalance += idealWinnerPrize;
                gs.gameData[gameID].virtualFraxBalance -= idealWinnerPrize;
                gs
                .playerBalanceData[gameID][msg.sender]
                    .loanedFraxBalance += uint120(idealWinnerPrize);
            }

            emit GameUpdated(gameID, msg.sender, idealWinnerPrize, ticketID);
        }
    }

    /**
        @notice Allows a player to make an offer for a ticket.
            If the offered amount is {MIN_TICKET_VALUE_OFFER}% higher than the current ticket value
                or just higher than the last offer
                the offer is accepted and stored, or else it will be reverted.
        @dev Allows a player to make an offer for a specific ticket.
            If a higher offer is made for the same ticket
                the previous offer is refunded to the maker.
            The player making the offer, must be an externally owned account (EOA).
        @param ticketID The ID of the winning ticket for which the offer is being made.
        @param amount The amount of the offer in {FRAX} tokens.
    */
    function offerOperation(uint8 ticketID, uint96 amount) external onlyEOA {
        GameStorage storage gs = GameStorageLib.gameStorage();

        uint256 gameID = gs.currentGameID;

        (
            Status stat,
            ,
            uint256 currentWave,
            bytes memory tickets
        ) = GameStatusLib.gameUpdate(gs.currentGameID);

        uint256 plus10PCT = GameTicketsLib.ticketValue(tickets.length, gameID);
        plus10PCT +=
            (plus10PCT * GameConstantsLib.MIN_TICKET_VALUE_OFFER()) /
            GameConstantsLib.BASIS();
        Offer memory O = gs.offer[gameID][ticketID];
        uint256 offerorStaleAmount = GameOffersLib.staleOffers(msg.sender);

        GameStatusLib.onlyOperational(currentWave, stat);
        GameTicketsLib.onlyWinnerTicket(tickets, ticketID);

        if (amount < plus10PCT)
            revert ONLY_HIGHER_THAN_CURRENT_TICKET_VALUE(amount, plus10PCT);

        if (amount <= O.amount)
            revert ONLY_HIGHER_THAN_CURRENT_OFFER_VALUE(amount, O.amount);

        if (offerorStaleAmount < amount) {
            uint256 diffOfferWithStaleAmount = amount - offerorStaleAmount;

            _transferFromHelper(
                msg.sender,
                GameImmutablesLib.TREASURY(),
                diffOfferWithStaleAmount
            );

            unchecked {
                gs
                    .offerorData[msg.sender]
                    .totalOffersValue += diffOfferWithStaleAmount;
            }
        }

        if (gs.offerorData[msg.sender].latestGameID != gameID) {
            gs.offerorData[msg.sender].latestGameID = uint160(gameID);
            gs.offerorData[msg.sender].latestGameIDoffersValue = uint96(amount);
        } else
            gs.offerorData[msg.sender].latestGameIDoffersValue += uint96(
                amount
            );

        if (O.maker != GameConstantsLib.ZERO_ADDRESS()) {
            _transferFromHelper(
                GameImmutablesLib.TREASURY(),
                O.maker,
                O.amount
            );

            unchecked {
                gs.offerorData[O.maker].totalOffersValue -= O.amount;
                gs.offerorData[O.maker].latestGameIDoffersValue -= O.amount;
            }
        }

        gs.offer[gameID][ticketID] = Offer(amount, msg.sender);

        emit OfferMade(msg.sender, ticketID, amount, O.maker);
    }

    /**
        @notice In a nutshell, it enables the players to claim the basic amount of participation
            in the game (buying tickets, offers) that they contracted
            and if they won, it also pays the player
            the profit of the winning amount of that game.
        @param gameID The ID of the game for which 
    */
    function claimOperation(uint256 gameID) external {
        GameStorage storage gs = GameStorageLib.gameStorage();

        if (gameID > gs.currentGameID) gameID = gs.currentGameID;
        (Status stat, , , bytes memory tickets) = GameStatusLib.gameUpdate(
            gameID
        );

        if (stat != Status.claimable) revert ONLY_CLAIMABLE_MODE(stat);

        uint256 playerInitialFraxBalance = gs
        .playerBalanceData[gameID][msg.sender].initialFraxBalance;
        uint256 playerLoanedFraxBalance = gs
        .playerBalanceData[gameID][msg.sender].loanedFraxBalance;

        if (
            tickets.length == 1 &&
            gs.tempTicketOwnership[gameID][uint8(tickets[0])] == msg.sender
        ) {
            playerLoanedFraxBalance += gs.gameData[gameID].virtualFraxBalance;
            delete gs.totalPlayerTickets[gameID][msg.sender];
        }

        if (playerInitialFraxBalance == 0) revert NO_AMOUNT_TO_CLAIM();

        uint256 chosenConfig = gs.gameData[gameID].chosenConfig;
        uint256 mooShare = (gs.gameStratConfig[chosenConfig].beefyVault)
            .getPricePerFullShare();
        uint256 gameMooBalance = gs.gameData[gameID].mooTokenBalance;
        // aware of underflow possibility - revert is desired.
        uint256 gameRewardedMoo = ((((gs.gameData[gameID].rewardedMoo +
            (((gameMooBalance * mooShare) / 1e18) -
                ((gameMooBalance * gs.gameData[gameID].mooShare) / 1e18))) *
            1e18) / ((gameMooBalance * mooShare) / 1e18)) *
            gs.gameData[gameID].mooTokenBalance) / 1e18;
        gameMooBalance -= gameRewardedMoo;

        uint256 gameInitialFraxBalance = gs.gameData[gameID].initialFraxBalance;
        uint256 gameLoanedFraxBalance = gs.gameData[gameID].loanedFraxBalance +
            gs.gameData[gameID].virtualFraxBalance;

        uint256 playerClaimableMooAmount;

        if (gameInitialFraxBalance == playerInitialFraxBalance) {
            playerClaimableMooAmount = gs.gameData[gameID].mooTokenBalance;

            delete gs.gameData[gameID].mooTokenBalance;
            delete gs.gameData[gameID].initialFraxBalance;
            delete gs.gameData[gameID].loanedFraxBalance;

            gs.gameData[gameID].tickets = tickets;
        } else {
            playerClaimableMooAmount =
                ((((playerInitialFraxBalance * 1e18) / gameInitialFraxBalance) *
                    (
                        gameLoanedFraxBalance == 0
                            ? gs.gameData[gameID].mooTokenBalance
                            : gameMooBalance
                    )) / 1e18) +
                (
                    gameLoanedFraxBalance == 0
                        ? 0
                        : (((playerLoanedFraxBalance * 1e18) /
                            gameLoanedFraxBalance) * gameRewardedMoo) / 1e18
                );

            gs.gameData[gameID].mooTokenBalance -= playerClaimableMooAmount;
            gs.gameData[gameID].initialFraxBalance -= playerInitialFraxBalance;
            if (gameLoanedFraxBalance != 0)
                gs.gameData[gameID].loanedFraxBalance -= gs
                .playerBalanceData[gameID][msg.sender].loanedFraxBalance;
        }

        delete gs.playerBalanceData[gameID][msg.sender];
        if (
            tickets.length == 1 &&
            gs.tempTicketOwnership[gameID][uint8(tickets[0])] == msg.sender
        ) delete gs.gameData[gameID].virtualFraxBalance;

        ICurveStableNG curveStableNG = gs
            .gameStratConfig[chosenConfig]
            .curveStableNG;
        uint256 beforeLPbalance = curveStableNG.balanceOf(
            GameImmutablesLib.THIS()
        );

        playerClaimableMooAmount.withdrawLPT(
            gs.gameStratConfig[chosenConfig].beefyVault
        );

        uint256 claimedAmount = (curveStableNG.balanceOf(
            GameImmutablesLib.THIS()
        ) - beforeLPbalance).burnLPT(
                msg.sender,
                gs.gameStratConfig[chosenConfig].fraxTokenPosition,
                curveStableNG
            );

        emit Claimed(
            gameID,
            msg.sender,
            claimedAmount,
            int256(claimedAmount) - int256(playerInitialFraxBalance)
        );
    }

    /**
        @notice Allows the player to take back their stale offers and receive a refund.
        @dev Enables the player to withdraw offers that have not been accepted
                and receive a refund in return.
            If the player has made an offer or offers in the {currentGameID}
                he/she can withdraw them only after the game is finished
                if they are not accepted.
            Only the player who made the offers can call this function.
    */
    function takeBackStaleOffers() external {
        uint256 refundableAmount = GameOffersLib.staleOffers(msg.sender);

        if (refundableAmount == 0) revert NO_AMOUNT_TO_REFUND();

        unchecked {
            GameStorageLib
                .gameStorage()
                .offerorData[msg.sender]
                .totalOffersValue -= refundableAmount;
        }

        _transferFromHelper(
            GameImmutablesLib.TREASURY(),
            msg.sender,
            refundableAmount
        );

        emit StaleOffersTookBack(msg.sender, refundableAmount);
    }

    /*****************************\
    |-*-*-*-*   PRIVATE   *-*-*-*-|
    \*****************************/
    /**
        @dev Allows the contract to transfer {FRAX} tokens from one address to another.
        @param from The address from which the {FRAX} tokens will be transferred.
        @param to The address to which the {FRAX} tokens will be transferred.
        @param amount The amount of {FRAX} tokens to be transferred.
    */
    function _transferFromHelper(
        address from,
        address to,
        uint256 amount
    ) private {
        GameImmutablesLib.FRAX().transferFrom(from, to, amount);
    }
}
