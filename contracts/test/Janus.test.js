const { expect } = require("chai");

describe("Janus", accounts => {

    let janus;
    let owner, alice, bob, addrs;

    beforeEach(async function () {
        [owner, alice, bob, ...addrs] = await ethers.getSigners();

        // await hre.network.provider.request({
        //     method: "hardhat_impersonateAccount",
        //     params: ["0xEB796bdb90fFA0f28255275e16936D25d3418603"]}
        // )
        // await hre.network.provider.request({
        //     method: "hardhat_impersonateAccount",
        //     params: ["0x49e565Ed1bdc17F3d220f72DF0857C26FA83F873"]}
        // )
        // await hre.network.provider.request({
        //     method: "hardhat_impersonateAccount",
        //     params: ["0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f"]}
        // )

        const Janus = await ethers.getContractFactory("Janus");
        janus = await Janus.deploy();
    });


    describe("Score Tests", accounts => {

        it("Should deploy contracts", async function () {
            expect(true).to.equal(true);
        });

    });

});
