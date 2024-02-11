// SPDX-License-Identifier: --256--
pragma solidity 0.8.18;

import {I256} from "./interfaces/I256.sol";
import {IUSDC} from "./interfaces/IUSDC.sol";

contract OfferorsTreasury {
    struct Offer {
        uint96 amount;
        address maker;
    }

    mapping(uint256 => mapping(uint256 => Offer)) public offer;

    I256 private immutable _game;
    IUSDC private immutable _usdc;
    string private constant _LT_ERR = "LOSER_TICKET";
    string private constant _OIPG_ERR = "ONLY_IN_PROGRESS_GAME";

    event OfferMade(
        address indexed maker,
        uint256 indexed ticketId,
        uint256 indexed amount
    );

    event OfferAccepted(
        address indexed newOwner,
        address indexed lastOwner,
        uint256 indexed ticketId,
        uint256 amount
    );

    constructor(address usdc_) {
        _game = I256(msg.sender);
        _usdc = IUSDC(usdc_);
    }

    function makeOffer(uint8 ticketId, uint96 amount) external {
        address sender = msg.sender;
        uint256 gameId = _game.currentGameID();
        (I256.Status stat, , , bytes memory tickets) = _game.getLatestUpdate();

        require(stat == I256.Status.inProcess, _OIPG_ERR);
        require(
            amount > offer[gameId][ticketId].amount &&
                amount > (_usdc.balanceOf(address(this)) / tickets.length),
            "Bye"
        );

        require(_linearSearch(tickets, ticketId));

        offer[gameId][ticketId] = Offer(amount, sender);

        emit OfferMade(sender, ticketId, amount);
    }

    function acceptOffers(uint8[] calldata ticketIds) external {}

    function takeBackStaleOffers() external {}

    function _linearSearch(bytes memory tickets, uint8 ticketId)
        public
        pure
        returns (bool)
    {

        for (uint256 i = tickets.length - 1; i >= 0; ) {
            if (uint8(tickets[i]) == ticketId) {
                return true;
            }

            unchecked {
                i--;
            }
        }
        return false;
    }
}
