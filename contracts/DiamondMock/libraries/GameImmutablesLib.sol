// SPDX-License-Identifier: -- Come2Top --
pragma solidity 0.8.20;

import {IERC20} from "../../interfaces/IERC20.sol";
import {IFraxtalL1Block} from "../../interfaces/IFraxtalL1Block.sol";
import {ICome2Top} from "../../interfaces/ICome2Top.sol";

library GameImmutablesLib {
    function MAGIC_VALUE() internal view returns (uint256) {
        return ICome2Top(address(this)).MAGIC_VALUE();
    }

    function FRAX() internal view returns (IERC20) {
        return IERC20(ICome2Top(address(this)).FRAX());
    }

    function TREASURY() internal view returns (address) {
        return ICome2Top(address(this)).TREASURY();
    }

    function THIS() internal view returns (address) {
        return address(this);
    }

    function FRAXTAL_L1_BLOCK() internal view returns (IFraxtalL1Block) {
        return IFraxtalL1Block(ICome2Top(address(this)).FRAXTAL_L1_BLOCK());
    }
}
