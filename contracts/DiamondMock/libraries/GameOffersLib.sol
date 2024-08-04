// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {GameStorageLib, GameStorage, Status} from "./GameStorageLib.sol";
import {GameStatusLib} from "./GameStatusLib.sol";

library GameOffersLib {
    /**
        @notice Retrieves the total stale offer amount for a specific offeror.
        @param offeror The address of the offeror for whom the stale offer amount is being retrieved.
        @return The total stale offer amount for the specified offeror.
    */
    function staleOffers(address offeror) internal view returns (uint256) {
        GameStorage storage gs = GameStorageLib.gameStorage();

        if (gs.offerorData[offeror].latestGameID == gs.currentGameID) {
            (Status stat, , , ) = GameStatusLib.gameUpdate(gs.currentGameID);

            if (stat != Status.commingWave && stat != Status.operational)
                return (gs.offerorData[offeror].totalOffersValue);

            return (gs.offerorData[offeror].totalOffersValue -
                gs.offerorData[offeror].latestGameIDoffersValue);
        }

        return (gs.offerorData[offeror].totalOffersValue);
    }
}
