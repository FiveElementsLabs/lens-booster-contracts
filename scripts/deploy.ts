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

  // const ManagerFactory = await hre.ethers.getContractFactory("CampaignManager");
  // const Manager = await ManagerFactory.deploy(deployer.address);

  // await Manager.deployed();

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
  console.log("tx: ", tx.hash);
  await tx.wait();

  const Campaign = await ethers.getContractAt(
    "LensCampaign",
    await Manager.addressesCampaignAd(0)
  );

  await usdc.approve(Campaign.address, 1e6);

  const tx2 = await Campaign.depositBudget(1e6);

  return {
    campaign: [await Manager.addressesCampaignAd(0)],
    manager: Manager.address,
  };
}

async function setStatsRand(res: any) {
  const campaignAddress = res.campaign;
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];
  let nonce = await ethers.provider.getTransactionCount(deployer.address);

  for (let i = 0; i < campaignAddress.length; i++) {
    const Campaing = await ethers.getContractAt(
      "LensCampaignMocked",
      campaignAddress[i]
    );

    let tx;
    for (let i = 0; i < 5; i++) {
      tx = await Campaing.modifyProfileArray(i, { nonce, gasLimit: 2000000 });
      console.log("modifyProfileArray", tx.hash);
      await tx.wait();
      console.log(`Adding ${i} to campaing. Nonce: ${nonce}`);
      nonce++;
      nonce = await addClicks(
        Math.ceil(Math.random() * 100),
        Campaing,
        i,
        nonce
      );

      nonce = await addActions(
        Math.ceil(Math.random() * 100),
        Campaing,
        i,
        nonce
      );
    }
  }
  console.log("Manager: ", res.manager);

  return {
    campaign: campaignAddress,
    manager: res.address,
  };
}

const addClicks = async (
  nClicks: any,
  Campaing: any,
  profileId: any,
  nonce: number
) => {
  let tx;
  for (let i = 0; i < nClicks; i++) {
    tx = await Campaing.handleClickMocked(profileId, {
      nonce,
      gasLimit: 2000000,
    });
    console.log("handleClick", tx.hash);
    await tx.wait();
    console.log(`Adding to ${profileId}: ${nClicks} clicks. Nonce: ${nonce}`);
    ++nonce;
  }
  return nonce;
};

const addActions = async (
  nActions: any,
  Campaing: any,
  profileId: any,
  nonce: number
) => {
  let tx;
  for (let i = 0; i < nActions; i++) {
    tx = await Campaing.handleActionMocked(profileId, {
      nonce,
      gasLimit: 2000000,
    });
    console.log("handleAction", tx.hash);
    await tx.wait();
    console.log(`Adding to ${profileId}: ${nActions} clicks. Nonce: ${nonce}`);

    ++nonce;
  }

  return nonce;
};

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
