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
      accounts: [
        "063b6d5c1358b3689dd713f0b9be34c8858ca95a26e4031a803ec30f5936cf18",
      ],
    },
  },
};
