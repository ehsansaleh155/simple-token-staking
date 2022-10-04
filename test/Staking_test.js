const StakingContract = artifacts.require("Staking");
contract("Staking", () => {
  it("has been deployed successfully", async () => {
    const Staking = await StakingContract.deployed();
    assert(Staking, "contract was not deployed");
  });
});
