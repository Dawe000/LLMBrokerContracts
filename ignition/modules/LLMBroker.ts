// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LLMBrokerModule = buildModule("LLMBroker", (m) => {
  const LLMBroker = m.contract("LLMBroker");

  return { LLMBroker };
});

export default LLMBrokerModule;
