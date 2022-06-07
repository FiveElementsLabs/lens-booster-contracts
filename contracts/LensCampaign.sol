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
    ///@dev LensHub Contract Polygon
    ILensHub public constant LensHub =
        ILensHub(0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d);
    ///@dev Denomination asset for payouts
    ERC20 public immutable rewardToken;
    ///@dev Publication id to be sponsored
    uint256 public immutable publicationId;

    constructor(ERC20 _asset, uint256 _publicationId) public {
        rewardToken = _asset;
        publicationId = _publicationId;
    }

    ///@notice function that wrap mirror from lens, and pay for mirroring
    function mirrorWrapper(DataTypes.MirrorData calldata vars) external {
        LensHub.mirror(vars);
    }

    ///@notice function to deposit funds to the campaign
    ///@param amount amount of tokens to deposit
    function deposit(uint256 amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);
    }
}
