//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "../interfaces/ILensHub.sol";
import "../interfaces/ICampaignManager.sol";
import {ERC20} from "../libraries/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface ILensCampaign {
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

    ///@dev Save basic campaign information

    struct CampaignInfo {
        ///@dev Publication id to be sponsored
        uint256 publicationId;
        ///@dev Lens UserId of the advertiser
        uint256 adProfileId;
        ///@dev Duration campaign in seconds
        uint256 campaignDuration;
        ///@dev timestamp in seconds when the campaign starts
        uint256 startCampaign;
    }

    ///@dev Inflensers stats
    struct InflensersInfo {
        ///@dev Store address of users by profileID
        mapping(uint256 => address) addressLensProfile;
        ///@dev profileId - bool - true if the profile is already payed for the post
        mapping(uint256 => bool) payedProfile;
        ///@dev userId that have posted the campaign
        uint256[] userIdPosted;
    }
    struct ToBePayed {
        ///@dev profileId - clickCounts to be payed
        mapping(uint256 => uint256) clickCountsToBePayed;
        ///@dev profileId - actionCounts to be payed
        mapping(uint256 => uint256) actionCountsToBePayed;
    }

    struct AlreadyPayed {
        ///@dev profileId - clickCounts already payed
        mapping(uint256 => uint256) clickCountsAlreadyPayed;
        ///@dev profileId - actionCounts to be payed
        mapping(uint256 => uint256) actionCountsAlreadyPayed;
    }

    ///@dev MAIN INFLENSER
    struct Inflenser {
        InflensersInfo inflensersInfo;
        ToBePayed toBePayed;
        AlreadyPayed alreadyPayed;
    }

    ///@dev MAIN CAMPAIGN
    struct Campaign {
        CampaignInfo campaignInfo;
        PayoutType payouts;
    }
}

// A contract that points to a publication and pays posts, clicks and events
contract LensCampaignMocked {
    ///@dev Owner of the contract (who deploys it)
    address public owner;
    ///@dev LensHub Contract Polygon
    ILensHub public constant LensHub =
        ILensHub(0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d);
    ///@dev Denomination asset for payouts
    ERC20 public immutable rewardToken;
    ///@dev Manager that start the campaign and users score
    ICampaignManager public immutable campaignManager;

    ///@dev Main Storage
    Campaign public campaign;
    Inflenser public inflenser;

    constructor(
        address _owner,
        ERC20 _asset,
        address _campaignManager,
        uint256 _adProfileId,
        uint256 _publicationId,
        uint256 _campaingDuration,
        uint256 _postPayout,
        uint256 _maxPostPayout,
        uint256 _clickPayout,
        uint256 _maxClickPayout,
        uint256 _actionPayout,
        uint256 _maxActionPayout
    ) {
        owner = _owner;
        rewardToken = _asset;
        campaignManager = ICampaignManager(_campaignManager);
        campaign.campaignInfo.adProfileId = _adProfileId;
        campaign.campaignInfo.publicationId = _publicationId;
        campaign.campaignInfo.campaignDuration = _campaingDuration;
        campaign.payouts.postPayout = _postPayout;
        campaign.payouts.maxPostPayout = _maxPostPayout;
        campaign.payouts.leftPostPayout = _maxPostPayout;
        campaign.payouts.clickPayout = _clickPayout;
        campaign.payouts.maxClickPayout = _maxClickPayout;
        campaign.payouts.leftClickPayout = _maxClickPayout;
        campaign.payouts.actionPayout = _actionPayout;
        campaign.payouts.maxActionPayout = _maxActionPayout;
        campaign.payouts.leftActionPayout = _maxActionPayout;
        campaign.campaignInfo.startCampaign = block.timestamp;
    }

    ///@notice modifier to check if an address is whitelisted
    modifier onlyWhitelisted(uint256 _profileId) {
        require(
            campaignManager.inflencerId(_profileId) != 0,
            "LensCampaign::onlyWhitelisted: UserId not whitelisted"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "LensCampaign::onlyOwner: Only owner");
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
            campaign.campaignInfo.campaignDuration +
                campaign.campaignInfo.startCampaign >=
                block.timestamp,
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
            campaign.campaignInfo.campaignDuration +
                campaign.campaignInfo.startCampaign <=
                block.timestamp,
            "LensCampaign::withdrawBudget: You can only withdraw when campaign is closed"
        );
        require(
            rewardToken.transfer(owner, rewardToken.balanceOf(address(this))),
            "LensCampaign::withdrawBudget: Cannot withdraw funds"
        );
    }

    ///@notice function that wrap post from lens, and pay for post
    ///@param _profileId profile id of the inflenser
    ///@param postData post data to be send to LensHub
    function handlePost(
        uint256 _profileId,
        DataTypes.PostWithSigData calldata postData
    ) external onlyWhitelisted(_profileId) notExpired {
        require(
            inflenser.inflenserInfo.payedProfile[_profileId] == false,
            "LensCampaing::handlePost: Post already payed"
        );

        uint256 pubId = LensHub.postWithSig(postData);

        require(pubId != 0, "LensCampaing::handlePost:Post not accepted");

        (bool success, uint256 newLeftPayout) = _payout(
            campaign.payouts.postPayout *
                campaignManager.inflencerId(_profileId),
            campaign.payouts.leftPostPayout,
            msg.sender
        );

        if (success) {
            inflenser.inflenserInfo.payedProfile[_profileId] = true;
            inflenser.inflenserInfo.userIdPosted.push(_profileId);
            campaign.payouts.leftPostPayout = newLeftPayout;

            inflenser.inflenserInfo.addressLensProfile[_profileId] = msg.sender;
        }
    }

    ///@notice function that increment the count of the clicks obtained by one inflenser
    ///@param _profileId profile id of the inflenser
    function handleClick(uint256 _profileId) external onlyGov {
        inflenser.toBePayed.clickCountsToBePayed[_profileId]++;
    }

    ///@notice function that increment the count of the actions obtained by one inflenser
    ///@param _profileId profile id of the inflenser
    function handleAction(uint256 _profileId) external onlyGov {
        inflenser.toBePayed.actionCountsToBePayed[_profileId]++;
    }

    ///@notice function called by the keeper for pay for clicks
    ///@param _toBePaid profile id of the inflenser
    ///@param nClick number of clicks for the payment
    function payForClick(uint256 _toBePaid, uint256 nClick)
        external
        onlyGov
        onlyWhitelisted(_toBePaid)
    {
        require(
            inflenser.toBePayed.clickCountsToBePayed[_toBePaid] >= nClick,
            "LensCampaign::payForClick: the number of clicks to pay is greater than the counter"
        );

        (bool success, uint256 newLeftPayout) = _payout(
            campaign.payouts.clickPayout * nClick,
            campaign.payouts.leftClickPayout,
            inflenser.inflenserInfo.addressLensProfile[_toBePaid]
        );

        if (success) {
            inflenser.toBePayed.clickCountsToBePayed[_toBePaid] -= nClick;
            inflenser.alreadyPayed.clickCountsAlreadyPayed[_toBePaid] += nClick;
            campaign.payouts.leftClickPayout = newLeftPayout;
        }
    }

    ///@notice function called by the keeper for pay for actions
    ///@param _toBePaid profile id of the inflenser
    ///@param nAction number of actions for the payment
    function payForAction(uint256 _toBePaid, uint256 nAction)
        external
        onlyGov
        onlyWhitelisted(_toBePaid)
    {
        require(
            inflenser.oBePayed.actionCountsToBePayed[_toBePaid] >= nAction,
            "LensCampaign::payForAction: the number of actions to pay is greater than the counter"
        );

        (bool success, uint256 newLeftPayout) = _payout(
            campaign.payouts.actionPayout * nAction,
            campaign.payouts.leftActionPayout,
            inflenser.inflenserInfo.addressLensProfile[_toBePaid]
        );

        if (success) {
            inflenser.oBePayed.actionCountsToBePayed[_toBePaid] -= nAction;
            inflenser.alreadyPayed.actionCountsAlreadyPayed[
                _toBePaid
            ] += nAction;
            campaign.payouts.leftActionPayout = newLeftPayout;
        }
    }

    ///@notice function that pays amount of the bugdet to the user
    ///@param amountToPay amount of tokens to pay
    ///@param leftPayout amount of tokens left to be used
    function _payout(
        uint256 amountToPay,
        uint256 leftPayout,
        address _addressToBePaid
    ) internal notExpired returns (bool, uint256) {
        require(
            amountToPay <= leftPayout,
            "LensCampaign::_payoutPost: Max payout exceeded"
        );

        require(
            rewardToken.transfer(
                _addressToBePaid,
                amountToPay <= leftPayout ? amountToPay : leftPayout
            ),
            "LensCampaign::_payoutPost: Transfer failed"
        );
        return (true, amountToPay <= leftPayout ? leftPayout - amountToPay : 0);
    }

    ///@dev mocked version only
    function modifyLeftPayout(
        uint256 leftPost,
        uint256 leftClick,
        uint256 leftAction
    ) external onlyOwner {
        campaign.payouts.leftPostPayout = leftPost;
        campaign.payouts.leftClickPayout = leftClick;
        campaign.payouts.leftActionPayout = leftAction;
    }

    function modifyProfileArray(uint256 _profileId) external onlyOwner {
        inflenser.inflenserInfo.userIdPosted.push(_profileId);
        inflenser.inflenserInfo.payedProfile[_profileId] = true;
    }

    ///@notice function that increment the count of the clicks obtained by one inflenser
    ///@param _profileId profile id of the inflenser
    function handleClickMocked(uint256 _profileId) external onlyGov {
        inflenser.alreadyPayed.clickCountsAlreadyPayed[_profileId]++;
    }

    ///@notice function that increment the count of the actions obtained by one inflenser
    ///@param _profileId profile id of the inflenser
    function handleActionMocked(uint256 _profileId) external onlyGov {
        inflenser.alreadyPayed.actionCountsAlreadyPayed[_profileId]++;
    }
}
