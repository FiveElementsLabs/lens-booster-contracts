// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

/**
 * @title Contract that saves profiles and scores
 */

contract profilesScore {
    address owner;
    // defining our Request struct
    struct Mapper {
        mapping(address => uint256) addressesBooster;
    }

    Mapper addressesMapper;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Owner");
        _;
    }

    // Values in the mapping are initialized as 0 / False
    modifier isWhitelisted(address _address) {
        require(addressesMapper.addressesBooster[_address] >= 1, "Whitelist");
        _;
    }

    function addUser(address _addressToWhitelist, uint256 _score)
        public
        onlyOwner
    {
        require(_score < 10, "score 1-10");
        addressesMapper.addressesBooster[_addressToWhitelist] = _score;
    }

    function userScore(address _whitelistedAddress)
        public
        view
        returns (uint256)
    {
        return addressesMapper.addressesBooster[_whitelistedAddress];
    }
}
