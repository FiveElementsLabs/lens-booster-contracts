//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "./interfaces/ILensHub.sol";
import "./interfaces/IProfileScore.sol";
import "hardhat/console.sol";
import {ERC20} from "./libraries/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// A contract that points to a publication and pays posts, clicks and events
contract LensCampaign is Ownable {
    ///@dev LensHub Contract Polygon
    ILensHub public constant LensHub =
        ILensHub(0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d);
    ///@dev Denomination asset for payouts
    ERC20 public immutable rewardToken;
    ///@dev Publication id to be sponsored
    uint256 public immutable publicationId;
    ///@dev Lens UserId
    uint256 public immutable userId;
    ///@dev Profile score contract
    IProfileScore public immutable profileScore;
    ///@dev Duration campaign in seconds
    uint256 public campaignDuration;
    uint256 public immutable startCampaign;

    mapping(address => bool) private payedAddress;

    ///@dev payout amount
    struct PayoutType {
        uint256 postPayout;
        uint256 maxPostPayout;
        uint256 leftPostPayout;
        uint256 clickPayout;
        uint256 maxClickPayout;
        uint256 leftClickPayout;
        uint256 actionPayout;
        uint256 maxActionPayout;
        uint256 leftActionPayout;
    }

    PayoutType public payouts;

    constructor(
        ERC20 _asset,
        address _profileScore,
        uint256 _publicationId,
        uint256 _userId,
        uint256 _campaingDuration,
        uint256 _postPayout,
        uint256 _maxPostPayout,
        uint256 _clickPayout,
        uint256 _maxClickPayout,
        uint256 _actionPayout,
        uint256 _maxActionPayout
    ) public {
        rewardToken = _asset;
        publicationId = _publicationId;
        profileScore = IProfileScore(_profileScore);
        userId = _userId;
        campaignDuration = _campaingDuration;
        payouts.postPayout = _postPayout;
        payouts.maxPostPayout = _maxPostPayout;
        payouts.leftPostPayout = _maxPostPayout;
        payouts.clickPayout = _clickPayout;
        payouts.maxClickPayout = _maxClickPayout;
        payouts.leftClickPayout = _maxClickPayout;
        payouts.actionPayout = _actionPayout;
        payouts.maxActionPayout = _maxActionPayout;
        payouts.leftActionPayout = _maxActionPayout;
        startCampaign = block.timestamp;
    }

    ///@notice modifier to check if an address is whitelisted
    modifier onlyWhitelisted() {
        require(
            profileScore.addressesBooster(msg.sender) != 0,
            "LensCampaign::onlyWhitelisted: Address not whitelisted"
        );
        _;
    }
    modifier onlyGov() {
        require(
            msg.sender == profileScore.governance(),
            "LensCampaign::onlonlyGovyKeeper: Only governance can call this function"
        );
        _;
    }
    modifier notExpired() {
        require(
            campaignDuration + startCampaign >= block.timestamp,
            "LensCampaign::notExpired: Time expired for campaign"
        );
        _;
    }

    ///@notice function to deposit funds to the campaign
    ///@param amount amount of tokens to deposit
    function depositBudget(uint256 amount) external onlyOwner notExpired {
        require(
            rewardToken.transferFrom(msg.sender, address(this), amount),
            "LensCampaign::depositBudget: Cannot transfer tokens"
        );
    }

    ///@notice function to withdraw funds from the campaign
    function withdrawBudget() external onlyOwner {
        require(
            campaignDuration + startCampaign <= block.timestamp,
            "LensCampaign::withdrawBudget: You can only withdraw when campaign is closed"
        );
        require(
            rewardToken.transfer(owner(), rewardToken.balanceOf(address(this))),
            "LensCampaign::withdrawBudget: Cannot withdraw funds"
        );
        campaignDuration = 0;
    }

    ///@notice function that wrap post from lens, and pay for post
    ///@param profileId profileId of the user
    ///@param postData post data to be send to LensHub
    function handlePost(
        uint256 profileId,
        DataTypes.PostWithSigData calldata postData
    ) external onlyWhitelisted notExpired {
        require(
            payedAddress[msg.sender] == false,
            "LensCampaing::handlePost: Post already posted"
        );

        uint256 pubId = LensHub.postWithSig(postData);

        require(pubId != 0, "LensCampaing::handlePost:Post not accepted");

        uint256 payout = (payouts.postPayout *
            profileScore.addressesBooster(msg.sender));
        (bool success, uint256 newLeftPayout) = _payout(
            payout,
            payouts.leftPostPayout
        );
        if (success) {
            payedAddress[msg.sender] = true;
            payouts.leftPostPayout = newLeftPayout;
        }
    }

    function payForClick(address _toBePaid, uint256 nClick) external onlyGov {
        require(
            profileScore.addressesBooster(_toBePaid) != 0,
            "LensCampaign::payForClick: Address not whitelisted"
        );

        uint256 payout = payouts.clickPayout * nClick;
        (bool success, uint256 newLeftPayout) = _payout(
            payout,
            payouts.leftClickPayout
        );
        if (success) payouts.leftClickPayout = newLeftPayout;
    }

    function payForAction(address _toBePaid, uint256 nAction) external onlyGov {
        require(
            profileScore.addressesBooster(_toBePaid) != 0,
            "LensCampaign::payForClick: Address not whitelisted"
        );

        uint256 payout = payouts.actionPayout * nAction;
        (bool success, uint256 newLeftPayout) = _payout(
            payout,
            payouts.leftActionPayout
        );
        if (success) payouts.leftActionPayout = newLeftPayout;
    }

    ///@notice function that pays amount of the bugdet to the user
    ///@param amountToPay amount of tokens to pay
    ///@param leftPayout amount of tokens left to be used
    function _payout(uint256 amountToPay, uint256 leftPayout)
        internal
        notExpired
        returns (bool, uint256)
    {
        require(
            amountToPay <= leftPayout,
            "LensCampaign::_payoutPost: Max payout exceeded"
        );

        require(
            rewardToken.transferFrom(
                address(this),
                msg.sender,
                amountToPay <= leftPayout ? amountToPay : leftPayout
            ),
            "LensCampaign::_payoutPost: Transfer failed"
        );
        return (true, amountToPay <= leftPayout ? leftPayout - amountToPay : 0);
    }
}
