import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";


/**
 * Test Plan:
 *  - mint
 *      - cost
 *      - mint
 *      - bind
 *  - transfer
 *      - transfer
 *      - transfer without binding
 *      - approved
 *      - approved for all
 *  - tokenUri
 */
describe("Only Token", function () {
    async function init() {
        // Contracts are deployed using the first signer/account by default

        const [owner, acc1, acc2] = await ethers.getSigners();
    
        const Only = await ethers.getContractFactory("Only");
        const only = await Only.deploy();
        
        return {only, owner, acc1, acc2, price: await only.ONLY_PRICE()};
    }

    describe("mint", function () {
        it("cost correctly", async function () {
            const num = 2;
            const {only, owner, price} = await loadFixture(init);

            // mint cost is correct
            const balance = await owner.getBalance();

            const tx = await only.mint(num, {value: price.mul(num)});
            const receipt = await tx.wait();

            const gasUsed = receipt.gasUsed.toBigInt() * receipt.effectiveGasPrice.toBigInt();
            const expectedBalance = balance.sub(ethers.BigNumber.from(price.mul(num))).sub(gasUsed);

            await expect(await owner.getBalance()).to.equal(expectedBalance);

            //not enough
            await expect(only.mint(num, {value: price.mul(num).sub(1)})).to.be.revertedWith("value sent is not enough");
        });
        
        it("mint correctly", async function () {
            const num = 2;
            const {only, price} = await loadFixture(init);

            
            await only.mint(num, {value: price.mul(num)});
            
            expect((await only.getOwnedTokens()).length).to.equal(num);
        });

        it("bind correctly", async function () {
            const {only, acc1, price} = await loadFixture(init);
            
            await only.mintAndBind(1, acc1.address, {value : price});
            expect((await only.getOwnedTokens()).length).to.equal(1);
            expect(await only.getBound()).to.equal(acc1.address);            
        })
    });

    describe("transfer",async function() {
        /**
         * 
         * 1.A mint two tokens(let's say t1,t2) and bind to B
         * 2.expect A own two tokens t1,t2
         * 3.expect B does not own any token
         * 4.transfer A -> B token t1
         * 5.expect A own token t2
         * 6.expect B own token t1
         * 7.transfer A -> C token t2
         * 8.expect reverted because of C is the bound of A
         */
        it("transfer", async function () {
            
            const {only, owner, acc1, acc2, price} = await loadFixture(init);
            
            await only.mintAndBind(2, acc1.address, {value : price.mul(2)});
            
            expect((await only.getOwnedTokens()).length).to.equal(2);
            expect((await only.connect(acc1).getOwnedTokens()).length).to.equal(0);
            
            
            const [t1, t2] = await only.connect(owner).getOwnedTokens();
            await only["safeTransferFrom(address,address,uint256)"](owner.address, acc1.address, t1);
            
            expect((await only.getOwnedTokens())[0]).to.equal(t2);
            expect((await only.connect(acc1).getOwnedTokens())[0]).to.equal(t1);
            
            expect(only.connect(owner)["safeTransferFrom(address,address,uint256)"](owner.address, acc2.address, t2))
            .to.be.revertedWith("cannot transfer token to address not bound");
        })
    })
});