import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
export default {
  solidity: {
    compilers: [
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
            details: {
              yul: true,
            },
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        enabled: true,
        url: "https://polygon-mainnet.g.alchemy.com/v2/OPgFJmubIEHEVanbQZQTswXK98J2vu8C",
      },
    },
    polygon: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/OPgFJmubIEHEVanbQZQTswXK98J2vu8C",
      //accounts: ["PVT_KEY"], adding your private key here for the account to be used
      accounts: [
        "4a584a58e9d6463d3dfaea32805f69bd21d16dce8b080daa927aa1e7f27d8dab",
      ],
    },
  },
};
