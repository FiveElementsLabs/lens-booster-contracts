//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "./interfaces/ILensHub.sol";
import "hardhat/console.sol";
import {ERC20} from "./libraries/ERC20.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// A contract that points to a publication and pays for mirroring
contract LensCampaign is Ownable {
    // LensHubAddress Polygon
    address public immutable lensHubAddress =
        0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
    ILensHub public lensHub;
    // Denomination asset for payouts
    ERC20 public immutable token;
    // Publication id to be sponsored
    uint256 public publicationId;

    // constructor
    constructor(ERC20 _asset) {
        ILensHub lensHub = ILensHub(lensHubAddress);
        token = _asset;
    }

    // Core functions
    // Mirror publication external
    function mirrorWrapper(DataTypes.MirrorData calldata vars) external {
        lensHub.mirror(vars);
    }

    // Get value of mirror
    function getMirrorValue() public view returns (uint256) {}

    // Fund the contract
    // Only who launches the campaign can do that
    function deposit(uint256 amount) external onlyOwner {
        token.transferFrom(msg.sender, address(this), amount);
    }

    // Set publication id to be mirrored
    function setPublication(uint256 id) external onlyOwner {
        publicationId = id;
    }
}
