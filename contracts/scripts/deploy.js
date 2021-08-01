const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {

    const [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", owner.address);
    console.log(`Owner [${owner.address}] Balance:`, ethers.utils.formatEther(await owner.getBalance()).toString());
    console.log(`Addr1 [${addr1.address}] Balance:`, ethers.utils.formatEther(await addr1.getBalance()).toString());
    console.log(`Addr2 [${addr2.address}] Balance:`, ethers.utils.formatEther(await addr2.getBalance()).toString());


    const Janus = await ethers.getContractFactory("Janus");
    const janus = await Janus.deploy();

    console.log(JSON.stringify({
        [hre.network.config.chainId]: {
            "Janus": janus.address,
        }
    }, null, 2));

    await janus.updateScore(
        owner.address,
        "50",
        "QmY6VMrktkKLWvUZQwxaBn4zdd19yjeiN3KeUygx3kcRZ3"
    );

    await janus.updateScore(
        addr1.address,
        "5",
        "QmY6VMrktkKLWvUZQwxaBn4zdd19yjeiN3KeUygx3kcRZ3"
    );

    await janus.updateScore(
        addr2.address,
        "15",
        "QmY6VMrktkKLWvUZQwxaBn4zdd19yjeiN3KeUygx3kcRZ3"
    );

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
