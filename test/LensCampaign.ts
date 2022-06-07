const hre = require("hardhat");
const { ethers } = require("hardhat");
import { Contract } from "ethers";
import { expect } from "chai";
import "mocha";
const ERC20Json = require("@openzeppelin/contracts/build/contracts/ERC20.json");
const LensHubJson = require("../contracts/abis/LensHub.json");
// Connect to the network
let provider = ethers.getDefaultProvider();

describe("LensCampaign", function () {
  let advertiser: any;
  let user: any;
  let lensCampaign: Contract;
  let USDC: Contract;
  let LensHub: Contract;
  const publicationURI = {
    version: "1.0.0",
    metadata_id: "855d5934-6ce4-4247-b4d7-e2c1b07b48b3",
    description: "inside this the link of redirect\nhttps://www.google.it/",
    content: "inside this the link of redirect\nhttps://www.google.it/",
    external_url: null,
    image: null,
    imageMimeType: null,
    name: "Post by @giaco.lens",
    attributes: [{ traitType: "string", key: "type", value: "post" }],
    media: [],
    appId: "Lenster",
  };

  before("Creating all environment", async function () {
    // lens profile five elements 0x7d06dE4aE53Ef27Fff2B34731C97bb44FD27D9E6 giaco.lens
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x7d06dE4aE53Ef27Fff2B34731C97bb44FD27D9E6"],
    });
    advertiser = await ethers.getSigner(
      "0x7d06dE4aE53Ef27Fff2B34731C97bb44FD27D9E6"
    );

    // lens profile user 0x30b0EAe5e9Df8a1C95dFdB7AF86aa4e7F3B51f13 luduvigo.lens
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x30b0EAe5e9Df8a1C95dFdB7AF86aa4e7F3B51f13"],
    });
    user = await ethers.getSigner("0x30b0EAe5e9Df8a1C95dFdB7AF86aa4e7F3B51f13");

    LensHub = await ethers.getContractAt(
      "ILensHub",
      "0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d"
    );

    // Advertiser deploys Campaign
    const LensCampaignFactory = await ethers.getContractFactory("LensCampaign");
    lensCampaign = await LensCampaignFactory.connect(advertiser).deploy(
      "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
      "12345"
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

    /* await USDC.connect(usdcProvider).transfer(advertiser.address, 2000e6);

    // Funding the campaign
    await lensCampaign.connect(advertiser).deposit(100e6); */
  });

  describe("LensCampaign mirrors", function () {
    it("should mirror a post", async function () {
      const beforePublications = await LensHub.getPubCount(12212);
      // Trying to mirror any post
      await LensHub.connect(advertiser).mirror({
        profileId: 12212, //giaco.lens profileId
        profileIdPointed: 306, //luduvigo.lens profileId
        pubIdPointed: 87, //luduvigo.lens pubId
        referenceModuleData: "0x0000000000000000000000000000000000000000",
        referenceModule: "0x0000000000000000000000000000000000000000",
        referenceModuleInitData: "0x0000000000000000000000000000000000000000",
      });
      /* await LensHub.connect(advertiser).post({
        profileId: 12212,
        contentURI: "",
        collectModule: "0x23b9467334beb345aaa6fd1545538f3d54436e96",
        collectModuleInitData: "0x0000000000000000000000000000000000000000",
        referenceModule: "0x0000000000000000000000000000000000000000",
        referenceModuleInitData: "0x0000000000000000000000000000000000000000",
      }); */
      /* uint256 profileId: 12212;
        string contentURI: https://ipfs.infura.io/ipfs/Qmaa3zzd6QAtGsVVuVEJhKZDHbYNKp5gh7s5tJva2ZhsRM;
        address collectModule: 0x23b9467334beb345aaa6fd1545538f3d54436e96;
        bytes collectModuleInitData: "0x0000000000000000000000000000000000000000";
        address referenceModule: "0x0000000000000000000000000000000000000000";
        bytes referenceModuleInitData: "0x0000000000000000000000000000000000000000" */
      const afterPublications = await LensHub.getPubCount(12212);
      expect(beforePublications.toNumber()).to.be.equal(
        afterPublications.toNumber() - 1
      );
    });

    it("Should check if post is success and payout the amount for it", async function () {
      // User sign a tx
      // We create a new ipfs with different links
      // Create postWithSig
      // Payout user

      expect(publicationURI.content.includes("https://www.google.it")).to.be
        .true;

      //call handleMirror with the post
    });

    it("should withdraw liquidity", async function () {});
  });
});
