import { ethers } from "hardhat";
import { collapseTextChangeRangesAcrossMultipleVersions } from "typescript";
const ERC20 = require("../artifacts/contracts/libraries/ERC20.sol/ERC20.json");

const hre = require("hardhat");

async function main() {
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];

  const usdc = await ethers.getContractAt(
    ERC20.abi,
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
  );

  const Manager = await ethers.getContractAt(
    "CampaignManager",
    "0x4F6579cEE9D7b0eE1018F92b0dE4256d18D36Ef9"
  );

  const tx = await Manager.createCampaign(
    usdc.address, // asset address
    "0x03ff", // userId 0x03ff-0x4c
    "0x4c", // pubId
    2e6, // duration
    1, // post payout
    100000000000, // max post payout
    1, // click payout
    100000000000, // max click payout
    0, // action payout
    100000000000 // max action payout
  );
  await tx.wait();

  const Campaign = await ethers.getContractAt(
    "LensCampaign",
    await Manager.addressesCampaignAd(0)
  );

  await usdc.approve(Campaign.address, 1e6);

  const tx2 = await Campaign.depositBudget(1e6);

  console.log(`Manager address: ${Manager.address}`);
  console.log(`Campaign address: ${await Manager.addressesCampaignAd(0)}`);

  return {
    campaign: [await Manager.addressesCampaignAd(0)],
    manager: Manager.address,
  };
}

const whitelist = async () => {
  const accounts = hre.ethers.getSigners();
  const deployer = accounts[0];

  const Manager = await ethers.getContractAt(
    "CampaignManager",
    "0x4F6579cEE9D7b0eE1018F92b0dE4256d18D36Ef9"
  );

  const tx = await Manager.setUserScore("0x0132", "1000", {
    gasLimit: 2000000,
  }); //profileID - score (0 - 1000)
};

const deposit = async () => {
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];

  const campaign = await ethers.getContractAt(
    "LensCampaign",
    "0x9f872Ce51a98b060c61591fA01fB67Ea760664B4"
  );

  const usdc = await ethers.getContractAt(
    ERC20.abi,
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
  );

  await usdc.approve(campaign.address, 1e6);

  const tx = await campaign.depositBudget(1e6, { gasLimit: 2000000 });
};

const payForClick = async () => {
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];

  const campaign = await ethers.getContractAt(
    "LensCampaign",
    "0x19C9995BFaB538426a3cb8C39F1B4797C9971041"
  );

  const usdc = await ethers.getContractAt(
    ERC20.abi,
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
  );

  const tx = await campaign.payForClick("0x2fb4", 1, { gasLimit: 2000000 });
};

//main().then((res) => console.log(res));
payForClick();
