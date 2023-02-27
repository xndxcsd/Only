import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
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
 *  - tokenURI
 */
describe("Only Token", function () {
    async function init() {
        // Contracts are deployed using the first signer/account by default

        const [owner, acc1, acc2] = await ethers.getSigners();

        const Only = await ethers.getContractFactory("Only");
        const only = await Only.deploy();

        console.log(`contract address is ${only.address}\n
        owner address is ${owner.address}\n
        acc1 address is ${acc1.address}\n
        acc2 address is ${acc2.address}\n`);

        return { only, owner, acc1, acc2, price: await only.ONLY_PRICE() };
    }

    describe("mint", function () {
        it("cost correctly", async function () {
            const num = 2;
            const { only, owner, price } = await loadFixture(init);

            // mint cost is correct
            const balance = await owner.getBalance();

            const tx = await only.mint(num, { value: price.mul(num) });
            const receipt = await tx.wait();

            const gasUsed = receipt.gasUsed.toBigInt() * receipt.effectiveGasPrice.toBigInt();
            const expectedBalance = balance.sub(ethers.BigNumber.from(price.mul(num))).sub(gasUsed);

            await expect(await owner.getBalance()).to.equal(expectedBalance);

            //not enough
            await expect(only.mint(num, { value: price.mul(num).sub(1) })).to.be.revertedWith("value sent is not enough");
        });

        it("mint correctly", async function () {
            const num = 2;
            const { only, price } = await loadFixture(init);


            await only.mint(num, { value: price.mul(num) });

            expect((await only.getOwnedTokens()).length).to.equal(num);
        });

        it("bind correctly", async function () {
            const { only, acc1, price } = await loadFixture(init);

            await only.mintAndBind(1, acc1.address, { value: price });
            expect((await only.getOwnedTokens()).length).to.equal(1);
            expect(await only.getBound()).to.equal(acc1.address);
        })
    });

    describe("transfer", async function () {
        /**
         * 
         * 1.A mint two tokens(let's say t1,t2) and bind to B
         * 2.expect A own two tokens t1,t2
         * 3.expect B does not own any token
         * 4.transfer A -> C token t2
         * 5.expect reverted because of C is the bound of A
         * 6.transfer A -> B token t1
         * 7.expect A own token t2
         * 8.expect B own token t1
         * 9.transfer A -> C token t2
         * 10.expect reverted because of C is the bound of A
         */
        it("transfer", async function () {

            const { only, owner, acc1, acc2, price } = await loadFixture(init);

            await only.mintAndBind(2, acc1.address, { value: price.mul(2) });
            const [t1, t2] = await only.connect(owner).getOwnedTokens();

            expect((await only.getOwnedTokens()).length).to.equal(2);
            expect((await only.connect(acc1).getOwnedTokens()).length).to.equal(0);

            expect(only.connect(owner)["safeTransferFrom(address,address,uint256)"](owner.address, acc2.address, t2))
                .to.be.revertedWith("cannot transfer token to address not bound");

            await only["safeTransferFrom(address,address,uint256)"](owner.address, acc1.address, t1);

            expect((await only.getOwnedTokens())[0]).to.equal(t2);
            expect((await only.connect(acc1).getOwnedTokens())[0]).to.equal(t1);

            expect(only.connect(owner)["safeTransferFrom(address,address,uint256)"](owner.address, acc2.address, t2))
                .to.be.revertedWith("cannot transfer token to address not bound");
        })

        /**
         * 
         * 1.A mint two tokens(let's say t1,t2)
         * 2.expect A own two tokens t1,t2
         * 3.expect B does not own any token
         * 4.transfer A -> B token t1
         * 5.expect A own token t2
         * 6.expect B own token t1
         * 7.transfer A -> C token t2
         * 8.expect reverted because of C is the bound of A
         */
        it("transfer without binding", async function () {
            const { only, owner, acc1, acc2, price } = await loadFixture(init);

            await only.mint(2, { value: price.mul(2) });
            const [t1, t2] = await only.connect(owner).getOwnedTokens();

            expect((await only.getOwnedTokens()).length).to.equal(2);
            expect((await only.connect(acc1).getOwnedTokens()).length).to.equal(0);

            await only.connect(owner)["safeTransferFrom(address,address,uint256)"](owner.address, acc1.address, t1);

            expect((await only.getOwnedTokens())[0]).to.equal(t2);
            expect((await only.connect(acc1).getOwnedTokens())[0]).to.equal(t1);

            expect(only.connect(owner)["safeTransferFrom(address,address,uint256)"](owner.address, acc2.address, t2))
                .to.be.revertedWith("cannot transfer token to address not bound");
        })

        /**
         * 1.A mint two tokens(let's say t1,t2)
         * 2.C transfer t1 from A to B
         * 3.expect reverted because of C is not the owner or be approved or operator for t1
         * 4.A approved C for t1
         * 5.expect C for t1 is approved by A
         * 5.C transfer t1 from A to B
         * 6.expect A own token t2
         * 7.expect B own token t1 
         */
        it("approved", async function () {
            const { only, owner, acc1, acc2, price } = await loadFixture(init);

            await only.mint(2, { value: price.mul(2) });
            const [t1, t2] = await only.connect(owner).getOwnedTokens();

            expect(only.connect(acc2)["safeTransferFrom(address,address,uint256)"](owner.address, acc1.address, t1))
                .to.be.revertedWith("caller is not the owner or approved to call");

            await only.connect(owner).approve(acc2.address, t1);
            expect(await only.getApproved(t1)).to.equal(acc2.address);

            await only.connect(acc2)["safeTransferFrom(address,address,uint256)"](owner.address, acc1.address, t1);

            expect((await only.connect(owner).getOwnedTokens())[0]).to.equal(t2);
            expect((await only.connect(acc1).getOwnedTokens())[0]).to.equal(t1);
        })

        /**
         * 1.A mint two tokens(let's say t1,t2)
         * 2.C transfer t1 from A to B
         * 3.expect reverted because of C is not the owner or be approved or operator for t1
         * 4.A approve C for all
         * 5.expect C for t1,t2 is approved by A
         * 6.C transfer t1 from A to B
         * 7.expect B own token t1
         * 8.A cancel approving C for all
         * 9.C transfer t2 from A to B
         * 10.expect reverted because of C is not the operator for t1
         */
        it("approved for all", async function () {
            const { only, owner, acc1, acc2, price } = await loadFixture(init);

            await only.mint(2, { value: price.mul(2) });
            const [t1, t2] = await only.connect(owner).getOwnedTokens();

            expect(only.connect(acc2)["safeTransferFrom(address,address,uint256)"](owner.address, acc1.address, t1))
                .to.be.revertedWith("caller is not the owner or approved to call");

            await only.connect(owner).setApprovalForAll(acc2.address, true);
            expect(await only.isApprovedForAll(owner.address, acc2.address)).to.be.true;

            await only.connect(acc2)["safeTransferFrom(address,address,uint256)"](owner.address, acc1.address, t1);
            expect((await only.connect(acc1).getOwnedTokens())[0]).to.equal(t1);
            expect((await only.connect(owner).getOwnedTokens())[0]).to.equal(t2);

            await only.connect(owner).setApprovalForAll(acc2.address, false);
            expect(only.connect(acc2)["safeTransferFrom(address,address,uint256)"](owner.address, acc1.address, t2))
                .to.be.revertedWith("caller is not the owner or approved to call");
        })
    });

    describe("tokenURI", async function () {
        it("tokenURI", async function () {
            const { only, price } = await loadFixture(init);

            await only.mint(1, { value: price });
            await expect(await only.tokenURI(1)).to.be.equal("ipfs://QmUEN7sfEUK2J2e3eRJiE3G7KmWkpCwBwx7rWUq557RKG9/token1.webp");
        })
    })
    
});