import { ethers } from "hardhat";

const hre = require("hardhat");

async function main() {
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];

  const ManagerFactory = await hre.ethers.getContractFactory("CampaignManager");
  const Manager = await ManagerFactory.deploy(deployer.address);
  //   const Manager = await ethers.getContractAt(
  //     "CampaignManager",
  //     "0xD5B48F2a649F315D1e2A7F95Ed807aeA2de84947"
  //   );
  await Manager.deployed();
  const tx = await Manager.createCampaign(
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174", // asset address
    "0x03ff", // pubId
    "0x4a", // userId
    2e6, // duration
    1, // post payout
    1000, // max post payout
    1, // click payout
    1000, // max click payout
    1, // action payout
    1000 // max action payout
  );
  console.log("tx: ", tx.hash);
  await tx.wait();
  console.log(await Manager.addressesCampaignAd(0));
}

async function setStatsRand(campaignAddress: any) {
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];
  let nonce = await ethers.provider.getTransactionCount(deployer.address);

  const Campaing = await ethers.getContractAt(
    "LensCampaignMocked",
    campaignAddress
  );

  let tx;
  for (let i = 0; i < 1; i++) {
    tx = await Campaing.modifyProfileArray(i, { nonce, gasLimit: 2000000 });
    console.log("modifyProfileArray", tx.hash);
    await tx.wait();
    console.log(`Adding ${i} to campaing. Nonce: ${nonce}`);
    nonce++;
    nonce = await addClicks(2, Campaing, i, nonce);

    nonce = await addActions(2, Campaing, i, nonce);
  }
}

setStatsRand("0xF48B5f5Ce3EEDbe73723373Eeeeffba2c8Def660")
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

const addClicks = async (
  nClicks: any,
  Campaing: any,
  profileId: any,
  nonce: number
) => {
  let tx;
  for (let i = 0; i < nClicks; i++) {
    tx = await Campaing.handleClick(profileId, { nonce, gasLimit: 2000000 });
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
    tx = await Campaing.handleAction(profileId, { nonce, gasLimit: 2000000 });
    console.log("handleAction", tx.hash);
    await tx.wait();
    console.log(`Adding to ${profileId}: ${nActions} clicks. Nonce: ${nonce}`);

    ++nonce;
  }

  return nonce;
};

// const test = async () => {
//   const accounts = await hre.ethers.getSigners();
//   const deployer = accounts[0];

//   const Campaing = await ethers.getContractAt(
//     "LensCampaignMocked",
//     "0x551277f0d5F51bC5149EbDe595c8963b9D074f15"
//   );

//   console.log(await Campaing.owner());
// };
// test();
