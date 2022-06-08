// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

/**
 * @title Contract that saves profiles and scores
 */

interface IProfileScore {
    function governance() external returns (address _governance);

    function addressesBooster(address) external returns (uint256);
}
