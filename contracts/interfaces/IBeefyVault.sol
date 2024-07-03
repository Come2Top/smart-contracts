//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IBeefyVault {
    /**
     * @dev The entrypoint of funds into the system. People deposit with this function
     * into the vault. The vault is then in charge of sending funds into the strategy.
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Function to exit the system. The vault will withdraw the required tokens
     * from the strategy and pay up the token holder. A proportional number of IOU
     * tokens are burned in the process.
     */
    function withdraw(uint256 shares) external;

    function getPricePerFullShare() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function want() external view returns (address);
}
