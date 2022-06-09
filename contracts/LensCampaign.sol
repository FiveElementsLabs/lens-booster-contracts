//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "./interfaces/ILensHub.sol";
import "./interfaces/ICampaignManager.sol";
import "hardhat/console.sol";
import {ERC20} from "./libraries/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// A contract that points to a publication and pays for mirroring a post
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
    ICampaignManager public immutable campaignManager;
    ///@dev Duration campaign in seconds
    uint256 public campaignDuration;
    uint256 public immutable startCampaign;
    ///@dev profileId - bool
    mapping(uint256 => bool) private payedProfile;
    ///@dev profileId - clickCounts
    mapping (uint256 => uint256) private clickCounts;

    ///@dev payout amounts
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

    ///@notice fired when a post is handled
    ///@param userId the id profile of the ad
    ///@param profileId the id profile of inflenser
    ///@param payout the payout of the post
    event PostPayed(uint256 userId, uint256 profileId, uint256 payout);

    ///@notice fired when clicks are payed
    ///@param userId the id profile of the ad
    ///@param profileId the id profile of inflenser
    ///@param payout the payout of the click
    ///@param clicks number of clicks payed
    event ClickPayed(uint256 userId, uint256 profileId, uint256 payout, uint256 clicks);

    ///@notice fired when actions are payed
    ///@param userId the id profile of the ad
    ///@param profileId the id profile of inflenser
    ///@param payout the payout of the actions
    ///@param nActions number of actions payed
    event ActionPayed(uint256 userId, uint256 profileId, uint256 payout, uint256 nActions);

    constructor(
        ERC20 _asset,
        address _campaignManager,
        uint256 _publicationId,
        uint256 _userId,
        uint256 _campaingDuration,
        uint256 _postPayout,
        uint256 _maxPostPayout,
        uint256 _clickPayout,
        uint256 _maxClickPayout,
        uint256 _actionPayout,
        uint256 _maxActionPayout
    ) {
        rewardToken = _asset;
        publicationId = _publicationId;
        campaignManager = ICampaignManager(_campaignManager);
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
    modifier onlyWhitelisted(uint256 _profileId) {
        require(
            campaignManager.idBooster(_profileId) != 0,
            "LensCampaign::onlyWhitelisted: UserId not whitelisted"
        );
        _;
    }

    ///@notice modifier to check if the caller is the gov
    modifier onlyGov() {
        require(
            msg.sender == campaignManager.governance(),
            "LensCampaign::onlonlyGovyKeeper: Only governance can call this function"
        );
        _;
    }

    ///@notice modifier to check if the campaign is not expired
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
            rewardToken.transfer(
                address(this),
                rewardToken.balanceOf(address(this))
            ),
            "LensCampaign::withdrawBudget: Cannot withdraw funds"
        );
        campaignDuration = 0;
    }

    ///@notice function that wrap post from lens, and pay for post
    ///@param _profileId profile id of the inflenser
    ///@param postData post data to be send to LensHub
    function handlePost(
        uint256 _profileId,
        DataTypes.PostWithSigData calldata postData
    ) external onlyWhitelisted (_profileId) notExpired {

        require(
            payedProfile[_profileId] == false,
            "LensCampaing::handlePost: Post already payed"
        );

        uint256 pubId = LensHub.postWithSig(postData);

        require(pubId != 0, "LensCampaing::handlePost:Post not accepted");

        uint256 payout = (payouts.postPayout *
            campaignManager.idBooster(_profileId));
        (bool success, uint256 newLeftPayout) = _payout(
            payout,
            payouts.leftPostPayout
        );
        if (success) {
            payedProfile[_profileId] = true;
            payouts.leftPostPayout = newLeftPayout;
            emit PostPayed(userId, _profileId, payout);
        }
    }

    ///@notice function that increment the count of the click obtained by one inflenser
    ///@param _profileId profile id of the inflenser
    function redirectOnClick (uint256 _profileId) external onlyGov 
    {
        clickCounts[_profileId]++;
    }

    ///@notice function called by the keeper for pay for clicks
    ///@param _toBePaid profile id of the inflenser
    ///@param click number of clicks for the payment
    function payForClick(uint256 _toBePaid, uint256 click) external onlyGov {
        require(
            campaignManager.idBooster(_toBePaid) != 0,
            "LensCampaign::payForClick: Address not whitelisted"
        );
        require(
            clickCounts[_toBePaid]>=click,
            "LensCampaign:payForClick: the number of clicks to pay is greater than the counter"
        );
        uint256 payout = payouts.clickPayout * click;
        (bool success, uint256 newLeftPayout) = _payout(
            payout,
            payouts.leftClickPayout
        );
        if (success){
            clickCounts[_toBePaid]-=click;
            payouts.leftClickPayout = newLeftPayout;
            emit ClickPayed(userId, _toBePaid, payout, click);
        } 
    }

    ///@notice function called by the keeper for pay for actions
    ///@param _toBePaid profile id of the inflenser
    ///@param nAction number of actions for the payment
    function payForAction(uint256 _toBePaid, uint256 nAction) external onlyGov {
        require(
            campaignManager.idBooster(_toBePaid) != 0,
            "LensCampaign::payForClick: Address not whitelisted"
        );

        uint256 payout = payouts.actionPayout * nAction;
        (bool success, uint256 newLeftPayout) = _payout(
            payout,
            payouts.leftActionPayout
        );
        if (success){
            payouts.leftActionPayout = newLeftPayout;
            emit ClickPayed(userId, _toBePaid, payout, nAction);
        }           
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
