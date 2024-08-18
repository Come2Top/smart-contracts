// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC165} from "../../interfaces/IERC165.sol";
import {IDiamondLoupe} from "../../interfaces/IDiamondLoupe.sol";

import {DiamondLib} from "../libraries/DiamondLib.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    /***************************************\
    |-*-*-*-*-*   DIAMOND-LOUPE   *-*-*-*-*-|
    \***************************************/
    /// @notice Gets all facets and their selectors.
    /// @return Facets.
    function facets() external view returns (Facet[] memory) {
        DiamondLib.DiamondStorage storage ds = DiamondLib.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        Facet[] memory allFacets = new Facet[](numFacets);

        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];

            allFacets[i].facetAddress = facetAddress_;
            allFacets[i].functionSelectors = ds
                .facetFunctionSelectors[facetAddress_]
                .functionSelectors;
        }

        return allFacets;
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param facet The facet address.
    /// @return Facet Function Selectors.
    function facetFunctionSelectors(address facet)
        external
        view
        returns (bytes4[] memory)
    {
        return
            DiamondLib
                .diamondStorage()
                .facetFunctionSelectors[facet]
                .functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return Facet Addresses.
    function facetAddresses() external view returns (address[] memory) {
        return DiamondLib.diamondStorage().facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param functionSelector The function selector.
    /// @return The facet address.
    function facetAddress(bytes4 functionSelector)
        external
        view
        returns (address)
    {
        return
            DiamondLib
                .diamondStorage()
                .selectorToFacetAndPosition[functionSelector]
                .facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return DiamondLib.diamondStorage().supportedInterfaces[interfaceId];
    }
}
