const hre = require("hardhat");
const { ethers } = require("hardhat");
import { Contract } from "ethers";
import { expect } from "chai";
import "mocha";
const ERC20Json = require("@openzeppelin/contracts/build/contracts/ERC20.json");
// Connect to the network
let provider = ethers.getDefaultProvider();

describe("LensCampaign", function () {
  let advertiser: any;
  let userWithoutProfile: any;
  let usdcMock: any;
  let lensCampaign: Contract;
  let USDC: Contract;

  before("Creating all environment", async function () {
    // lens profile five elements 0x7dcb4f75FF612Cf94E0b918160cbE55bE1C7b97d
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x7dcb4f75FF612Cf94E0b918160cbE55bE1C7b97d"],
    });
    const advertiser = await ethers.getSigner(
      "0x7dcb4f75FF612Cf94E0b918160cbE55bE1C7b97d"
    );

    // lens profile user 0x30b0EAe5e9Df8a1C95dFdB7AF86aa4e7F3B51f13
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x30b0EAe5e9Df8a1C95dFdB7AF86aa4e7F3B51f13"],
    });
    const user = await ethers.getSigner(
      "0x30b0EAe5e9Df8a1C95dFdB7AF86aa4e7F3B51f13"
    );

    // Advertiser deploys Campaign
    const LensCampaignFactory = await ethers.getContractFactory("LensCampaign");
    lensCampaign = await LensCampaignFactory.connect(advertiser).deploy(
      "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
    );
    await lensCampaign.deployed();
    // Approving USDC for advertiser
    USDC = await ethers.getContractAtFromArtifact(
      ERC20Json,
      "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
    );

    await USDC.connect(advertiser).approve(
      lensCampaign.address,
      ethers.utils.parseEther("1000000000")
    );

    // Initializing lens hub

    // Giving some USDC to advertisers. USDC taken from 0xCAb72c950D3971baF129392edF644A6cB4A18be1
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xCAb72c950D3971baF129392edF644A6cB4A18be1"],
    });
    const usdcProvider = await ethers.getSigner(
      "0xCAb72c950D3971baF129392edF644A6cB4A18be1"
    );
    /*
    await USDC.connect(usdcProvider).transfer(advertiser.address, 2000e6);

    // Funding the campaign
    await lensCampaign.connect(advertiser).deposit(100e6);

    // Trying to mirror any post
    await lensCampaign.connect(advertiser).mirrorWrapper({
      profileId: 7700,
      profileIdPointed: 452,
      pubIdPointed: 4,
      referenceModuleData: "0x",
      referenceModule: "0x0000000000000000000000000000000000000000",
      referenceModuleInitData: "0x",
    });*/
  });

  describe("LensCampaign mirrors", function () {
    it("Advertiser should fund the campaign", async function () {});

    it("should withdraw liquidity", async function () {});
  });
});
