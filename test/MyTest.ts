import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";


/**
 * Test Plan:
 *  - mint
 *  - transfer
 *      - approved
 *      - approved for all
 *      - transfer
 *      - transfer without binding
 *  - tokenUri
 */
describe("Only Token", function () {
    async function init() {
        // Contracts are deployed using the first signer/account by default
        const [owner, acc1, acc2] = await ethers.getSigners();
    
        const Only = await ethers.getContractFactory("Only");
        const only = await Only.deploy();
    
        return {only, owner, acc1, acc2};
    }

    // describe("mint", function () {
    //     it("mint", )

    // });

});