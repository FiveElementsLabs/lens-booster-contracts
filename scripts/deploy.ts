import { ethers } from "hardhat";
import { collapseTextChangeRangesAcrossMultipleVersions } from "typescript";

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

  console.log(await Manager.governance());
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
  return {
    campaign: await Manager.addressesCampaignAd(0),
    manager: Manager.address,
  };
}

async function setStatsRand(res: any) {
  const campaignAddress = res.campaign;
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];
  let nonce = await ethers.provider.getTransactionCount(deployer.address);

  const Campaing = await ethers.getContractAt(
    "LensCampaignMocked",
    campaignAddress
  );

  let tx;
  for (let i = 0; i < 5; i++) {
    tx = await Campaing.modifyProfileArray(i, { nonce, gasLimit: 2000000 });
    console.log("modifyProfileArray", tx.hash);
    await tx.wait();
    console.log(`Adding ${i} to campaing. Nonce: ${nonce}`);
    nonce++;
    nonce = await addClicks(Math.ceil(Math.random() * 100), Campaing, i, nonce);

    nonce = await addActions(
      Math.ceil(Math.random() * 100),
      Campaing,
      i,
      nonce
    );
  }
  console.log("Campaign: ", Campaing.address);
  console.log("Manager: ", res.manager);

  return {
    campaign: Campaing.address,
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

main()
  .then((res) => setStatsRand(res))
  .then(() => test());

/*setStatsRand({
  campaign: "0x74315519D80D3a0bF18EF867D691f6c9c4fAc669",
  manager: "0x00000000",
})*/
const test = async () => {
  const accounts = await hre.ethers.getSigners();
  const deployer = accounts[0];

  const CampaignManager = await ethers.getContractAt(
    "CampaignManager",
    "0xD0798f8308EFE28516C36D5d0dC31f68fD8D0d05",
    deployer
  );

  const Campaign = await ethers.getContractAt(
    "LensCampaignMocked",
    "0xdD994D28CEd09916F60eb36d4692fDC679998276",
    deployer
  );
  await Campaign.handleClick(18);
  console.log(await CampaignManager.governance());

  console.log(await Campaign.owner());
};
