// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const NUM = 10;

const testModule = buildModule("testModule", (m) => {
  const num = m.getParameter("unlockTime", NUM);

  const test = m.contract("test", [num]);

  return { test };
});

export default testModule;
