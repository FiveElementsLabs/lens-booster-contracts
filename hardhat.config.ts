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
  //4a584a58e9d6463d3dfaea32805f69bd21d16dce8b080daa927aa1e7f27d8dab gov
  //1f82dd494bfcc9fe2d280f0aa7bc3e66ecd78ad3e0d5e23378b9337f02959405 owner
  networks: {
    hardhat: {
      forking: {
        enabled: true,
        url: "https://polygon-mainnet.g.alchemy.com/v2/OPgFJmubIEHEVanbQZQTswXK98J2vu8C",
      },
    },
    polygon: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/OPgFJmubIEHEVanbQZQTswXK98J2vu8C",
      accounts: [
        "4a584a58e9d6463d3dfaea32805f69bd21d16dce8b080daa927aa1e7f27d8dab",
      ],
    },
  },
};
