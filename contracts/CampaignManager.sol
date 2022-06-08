// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

/**
 * @title Contract that saves profiles and scores
 */
import "hardhat/console.sol";

contract CampaignManager {
    address public governance;

    mapping(uint256 => uint256) public idBooster;

    constructor(address _governance) public {
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
        console.log("%s",_idToWhitelist);
        console.log("%s", _score);
        require(
            _score <= 100,
            "ProfileScore::setUserScore: Score must be between 1 and 10"
        );
        idBooster[_idToWhitelist] = _score;
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
