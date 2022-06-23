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

  // const ManagerAddress = await ethers.getContractFactory("CampaignManager");
  // const Manager = await ManagerAddress.deploy(deployer.address);
  // await Manager.deployed();

  const Manager = await ethers.getContractAt(
    "CampaignManager",
    "0xC537A74EE49D085Ea907203200C7E27Beb35A315"
  );

  await usdc.approve(Manager.address, 1e6);
  const tx = await Manager.createCampaign(
    usdc.address, // asset address
    "0x03ff", // userId 0x03ff-0x4c
    "0x4c", // pubId
    30000, // duration
    1, // post payout
    10000, // max post payout
    1, // click payout
    100, // max click payout
    0, // action payout
    0, // max action payout
    { gasLimit: 3000000 }
  );
  await tx.wait();

  try {
    for (let i = 0; i < 100; i++) {
      console.log(`Campaign address: ${await Manager.addressesCampaignAd(i)}`);
    }
  } catch (e) {
    console.log(e);
  }
  console.log(`Manager address: ${Manager.address}`);

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
    "0xC537A74EE49D085Ea907203200C7E27Beb35A315"
  );

  const tx = await Manager.setUserScore("0x6091", "1000", {
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
    "0x164785d43c7881C70ce1cdd2de80c3C5265AfaB2"
  );

  const usdc = await ethers.getContractAt(
    ERC20.abi,
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
  );

  const tx = await campaign.payForClick("0x2fb4", 1, { gasLimit: 2000000 });
};

main().then((res) => console.log(res));
//whitelist();
//withdraw
//payForClick();
