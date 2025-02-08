import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";


dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      evmVersion: "paris",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },


  defaultNetwork:"coston2",
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,// || "", // Sepolia RPC URL
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [], // Your private key
    },
    coston2: {
      url: process.env.COSTON2_RPC_URL,// || "", // Sepolia RPC URL
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [], // Your private key
    },
  }
  
};

export default config;
