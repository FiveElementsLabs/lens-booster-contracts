import { ethers } from "hardhat";
import { readFileSync } from "fs";
import fetch from "cross-fetch";
import { config as dotenvConfig } from "dotenv";
import { resolve } from "path";
//import  { addressCampaignManager }  from "./addresses"; //for mainnet de-comment it
import abiCampaignManagerJson from "../artifacts/contracts/CampaignManager.sol/CampaignManager.json";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

dotenvConfig({ path: resolve(__dirname, "../.env") });

async function main() {
  const provider = ethers.provider;

  const privateKey = process.env.PRIVATE_KEY;
  if (!privateKey) throw new Error("Private key is required.");

  let wallet = new ethers.Wallet(privateKey, provider);

  //----------------------------------------------------------------------- for mainnet swap these two
  //on local i have to redeploy every time
  let account = {} as SignerWithAddress;
  [account] = await ethers.getSigners();
  const CampaignManager = await ethers.getContractFactory("CampaignManager");
  const campaignManager = await CampaignManager.connect(account).deploy(
    account.address
  );
  await campaignManager.deployed();
  let nonce = await provider.getTransactionCount(account.address);

  //commentend for local development
  /* 
  const campaignManager = new Contract(    //checkthis
    addressCampaignManager, 
    abiCampaignManager[abi],
    wallet
  );
  let nonce = await provider.getTransactionCount(wallet.address);*/
  //----------------------------------------------------------------------- for mainnet swap these two

  //set gaslimit, gasprice

  const gasLimit = 3e6;
  const res = await fetch(
    "https://api.polygonscan.com/api?module=gastracker&action=gasoracle"
  );
  const gas = await res.json();
  const gasPrice = Number(Number(gas.result.ProposeGasPrice).toFixed(0)) * 1e9;

  let csv = readFileSync("whitelisted_profiles_list.csv");
  let array = csv.toString().split("\n");

  //upload
  for (let i = 1; i < 4; i++) {
    let id = array[i].split(",")[0];
    let score = Number(Number(array[i].split(",")[1]) * 100).toFixed(0);
    console.log(array[i]);

    await campaignManager.connect(account).setUserScore(id, score, {
      gasPrice,
      gasLimit,
      nonce,
    });

    nonce++;
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
