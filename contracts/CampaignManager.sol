// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import {ERC20} from "./libraries/ERC20.sol";
import "./LensCampaign.sol";

/**
 * @title Contract that saves profiles and scores
 */
import "hardhat/console.sol";

contract CampaignManager {

    address public governance;
    ///@dev ProfileId - Score
    mapping(uint256 => uint256) public idBooster;
    ///@dev UserIdAdd - PubIdAd - AddressCampaignAd
    mapping(uint256 => mapping(uint256=>address)) public addressesCampaign;

    ///@notice fired when a new campaign is created
    ///@param campaign the address of the campaign created
    ///@param userId the adv profile id
    event CampaignCreated(address campaign, uint256 userId);

    constructor(address _governance) {
        require(
            _governance != address(0),
            "Constructor: Governance address cannot be 0"
        );
        governance = _governance;
    }

    ///@notice modifier to check if the caller is the governance
    modifier onlyGov() {
        require(
            msg.sender == governance,
            "ProfileScore::onlyOwner: Only governance can call this function"
        );
        _;
    }

    ///@notice function that add user to whitelist, with is score
    ///@param _idToWhitelist address to add to whitelist
    ///@param _score score of the address added in whitelist
    function setUserScore(uint256 _idToWhitelist, uint256 _score)
        external
        onlyGov
    {
        require(
            _score <= 1000,
            "ProfileScore::setUserScore: Score must be between 1 and 10"
        );
        idBooster[_idToWhitelist] = _score;
    }

    ///@notice function for create a campaign
    ///@param _asset reward token
    ///@param _publicationId pubId of the post of the campaign
    ///@param _userId profile id of the owner of the campaign
    ///@param _campaingDuration duration of the campaign
    ///@param _postPayout payout per post
    ///@param _maxPostPayout budget of payouts per post
    ///@param _clickPayout payout per click
    ///@param _maxClickPayout budget of payouts per click
    ///@param _actionPayout payout per action
    ///@param _maxActionPayout budget of payouts per action
    function createCampaign(
        ERC20 _asset,
        uint256 _publicationId,
        uint256 _userId,
        uint256 _campaingDuration,
        uint256 _postPayout,
        uint256 _maxPostPayout,
        uint256 _clickPayout,
        uint256 _maxClickPayout,
        uint256 _actionPayout,
        uint256 _maxActionPayout
    ) external {
        LensCampaign campaign = new LensCampaign(
         _asset,
         address(this),
         _publicationId,
         _userId,
         _campaingDuration,
         _postPayout,
         _maxPostPayout,
         _clickPayout,
         _maxClickPayout,
         _actionPayout,
         _maxActionPayout
         );
        require (
            address(campaign)!=address(0),
            "CampaignManager::createCampaign: campaign not created"
        );
        addressesCampaign[_userId][_publicationId]=address(campaign);

        emit CampaignCreated(address(campaign), _userId);
    }


    ///@notice function to change governance address
    ///@param _governance new governance address
    function changeGovernance(address _governance) external onlyGov {
        require(
            _governance != address(0),
            "ProfileScore::changeGovernance: new governance cannot be 0"
        );
        governance = _governance;
    }


}