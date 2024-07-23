// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

import {DiamondLib} from "../libraries/DiamondLib.sol";

contract DiamondCutFacet is IDiamondCut {
    /*************************************\
    |-*-*-*-*-*   DIAMOND-CUT   *-*-*-*-*-|
    \*************************************/
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall.
    /// @param dc Contains the facet addresses and function selectors.
    /// @param init The address of the contract or facet to execute calldata.
    /// @param cd A function call, including function selector and arguments.
    /// cd is executed with delegatecall on init.
    function diamondCut(
        FacetCut[] calldata dc,
        address init,
        bytes calldata cd
    ) external {
        DiamondLib.enforceIsContractOwner();
        DiamondLib.diamondCut(dc, init, cd);
    }
}
