const { expect } = require("chai");
const { ethers } = require("hardhat");

//TODO: tests for fees

describe("Marketplace", function () {
  before(async function () {
    const [owner, acc1, acc2, acc3] = await ethers.getSigners();
    const initialMint = 20;

    global.owner = owner;
    global.acc1 = acc1;
    global.acc2 = acc2;
    global.acc3 = acc3;

    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await Marketplace.deploy();
    await marketplace.deployed();
    global.marketplace = marketplace

    const N721 = await ethers.getContractFactory("NFT721");
    const n721 = await N721.deploy();
    await n721.deployed();
    global.n721 = n721

    const N721A = await ethers.getContractFactory("NFT721A");
    const n721A = await N721A.deploy(initialMint);
    await n721A.deployed();
    global.n721A = n721A;

    const N1155 = await ethers.getContractFactory("NFT1155");
    const n1155 = await N1155.deploy(initialMint);
    await n1155.deployed();
    global.n1155 = n1155;
  });

  describe("¤¤NFT Marketplace¤¤", function () {

    describe("_Testing NFT contracts_", async () => {


      // base tests of {ERC721} NFT - see ERC721 for full coverage testing
      it("1) it should correctly test 721", async () => {
        expect(await n721.name()).to.equal("721test")

        expect(await n721.symbol()).to.equal("721")

        expect(await n721.totalSupply()).to.equal(3)

        await n721.mint(3)

        expect(await n721.totalSupply()).to.equal(6)
      })

      // base tests of {ERC721A} NFT - see ERC721A for full coverage testing
      it("2) it should correctly test 721a", async () => {
        expect(await n721A.name()).to.equal("721Atest")

        expect(await n721A.symbol()).to.equal("721a")

        expect(await n721A.totalSupply()).to.equal(20)

        await n721A.mint(5)

        expect(await n721A.totalSupply()).to.equal(25)
      })

      // base tests of {ERC1155} NFT - see ERC1155 for full coverage testing
      it("3) it should correctly test 1155", async () => {
        expect(await n1155.uri(1)).to.not.equal("")

        expect(await n1155.totalSupply(1)).to.equal(20)

        await n1155.mint(1, 10)

        expect(await n1155.totalSupply(1)).to.equal(30)
      })
    })
    describe("_Creating sales_", async () => {


      //Check no offer is yet registered
      it("1) it should have no offers registered yet", async () => {
        let offer1 = await marketplace.getOffer(1)

        expect(offer1.seller).to.equal("0x0000000000000000000000000000000000000000")
      })

      // createSale() revert on not approved for {ERC721}
      it("2) it should revert with 'ERC721: caller is not token owner nor approved' when a submitting a new sale order without approval - ERC721 -", async () => {
        expect(await n721.ownerOf(1)).to.equal(owner.address)

        await expect(marketplace.createSale(n721.address, 1, 1)).to.be.revertedWith('ERC721: caller is not token owner nor approved')
      })

      // createSale() success and parameters verifications for {ERC721}
      it("3) it should create a sale and offer1 have seller, contract address, price , tokenId, standard be ERC721 and closed be false - ERC721 - ", async () => {
        expect(await n721.ownerOf(1)).to.equal(owner.address)

        await n721.setApprovalForAll(marketplace.address, true)

        await marketplace.createSale(n721.address, 1, 1)

        let offer1 = await marketplace.getOffer(1)
        expect(offer1.seller).to.equal(owner.address)

        expect(offer1.contractAddress).to.equal(n721.address)

        expect(offer1.closed).to.equal(false)

        expect(offer1.price).to.equal(ethers.utils.parseEther("1"))

        expect(offer1.tokenId).to.equal(1)

        expect(offer1.standard).to.equal("ERC721")
      })

      // createSale() revert on not approved for {ERC721}
      it("4) it should revert with 'ERC1155: caller is not token owner nor approved' when a submitting a new sale order without approval - ERC1155 -", async () => {
        expect(await n1155.balanceOf(owner.address, 1)).to.not.equal(0)

        await expect(marketplace.createSale(n1155.address, 1, 1)).to.be.revertedWith('ERC1155: caller is not token owner nor approved')
      })

      // createSale() success and parameters verifications for {ERC1155}
      it("5) it should create a sale and offer2 have seller, contract address, price , tokenId, standard be ERC1155 and closed be false, - ERC1155 - ", async () => {
        expect(await n1155.balanceOf(owner.address, 1)).to.not.equal(0)

        await n1155.setApprovalForAll(marketplace.address, true)

        await marketplace.createSale(n1155.address, 1, 1)

        let offer2 = await marketplace.getOffer(2)

        expect(offer2.seller).to.equal(owner.address)

        expect(offer2.contractAddress).to.equal(n1155.address)

        expect(offer2.closed).to.equal(false)

        expect(offer2.price).to.equal(ethers.utils.parseEther("1"))

        expect(offer2.tokenId).to.equal(1)

        expect(offer2.standard).to.equal("ERC1155")
      })


      // succesful 'Transfer' & 'SaleCreated' event for createSale()
      it("6) it should create a sale & emit a 'Transfer' event & a 'SaleCreated' event", async () => {
        expect(await n721.ownerOf(2)).to.equal(owner.address)

        await n721.setApprovalForAll(marketplace.address, true)

        await expect(marketplace.createSale(n721.address, 2, 1)).to.emit(n721, 'Transfer').withArgs(owner.address, marketplace.address, 2)

        await expect(marketplace.createSale(n721.address, 3, 1)).to.emit(marketplace, 'SaleCreated').withArgs(4, owner.address, 3, n721.address, "ERC721", ethers.utils.parseEther("1"))
      })

      // createSale() revert when trying to sell a {ERC721} NFT not owned
      it("7) it should revert with 'not owner' when an address creates a sale for a NFT (erc721) it doesn't own ", async () => {
        await n721.connect(acc1).mint(2)

        expect(await n721.ownerOf(6)).to.not.equal(acc2.address)

        await expect(marketplace.connect(acc2).createSale(n721.address, 6, 2)).to.be.revertedWith('not owner')
      })

      // createSale() revert when trying to sell a {ERC1155} NFT not owned
      it("8) it should revert with 'not owner' when an address creates a sale for a NFT (erc1155) it doesn't own ", async () => {
        await n1155.connect(acc1).mint(1, 5)

        expect(await n1155.balanceOf(acc2.address, 1)).to.equal(0)

        await expect(marketplace.connect(acc2).createSale(n1155.address, 1, 2)).to.be.revertedWith('not owner')
      })

      //TODO: create sale revert on non recognized standard

      // modifySale() revert on not owner modification
      it("9) it should revert with 'not owner' when an other address than the seller tries to modify it ", async () => {
        await expect(marketplace.connect(acc1).modifySale(1, 2)).to.be.revertedWith("not owner")
      })

      // modifySale success
      it("10) it should have owner of a sale able to modify it", async () => {
        let price1Tx = await marketplace.getOffer(1)

        await (marketplace.modifySale(1, 2))

        let price2Tx = await marketplace.getOffer(1)

        expect(price1Tx.price).to.not.equal(price2Tx.price)
      })


      // cancelSale success with offer & event
      it("11) it should successfully cancel a sale order and send a SaleCanceled event", async () => {
        let offer1 = await marketplace.getOffer(1)

        expect(offer1.closed).to.equal(false)

        await expect(marketplace.cancelSale(1)).to.emit(marketplace, 'SaleCanceled').withArgs(1)

        offer1 = await marketplace.getOffer(1)

        expect(offer1.closed).to.equal(true)
      })

      // cancelSale() revert on offer closed
      it("12) it should revert if sale is already closed", async () => {
        let offer1 = await marketplace.getOffer(1)

        expect(offer1.closed).to.equal(true)

        await expect(marketplace.cancelSale(1)).to.be.revertedWith('offer is closed')
      })

      // cancelSale() revert on not owner
      it("13) it should revert with 'not owner' if not the owner tries to cancel the sale", async () => {
        await expect(marketplace.connect(acc1).cancelSale(2)).to.be.revertedWith('not owner')
      })
    })

    describe("_Offers_ -Buy sale, make offer, cancel offer, accept offer", async () => {

      // buySale() revert wrong amount
      it("1) it should revert if not right amount of ether is supplied", async () => {
        await expect(marketplace.connect(acc1).buySale(2, { value: ethers.utils.parseEther("0.5") })).to.be.revertedWith('not the right amount')
      })

      // buySale() success
      it("2) it should succesfully buy sale order 1 and be new owner of NFT", async () => {
        let offer3 = await marketplace.getOffer(3)

        expect(offer3.seller).to.equal(owner.address)

        expect(offer3.buyer).to.equal("0x0000000000000000000000000000000000000000")

        await expect(marketplace.connect(acc1).buySale(3, { value: ethers.utils.parseEther("1.0") })).to.emit(marketplace, "SaleSuccessful").withArgs(3, offer3.seller, acc1.address, offer3.price)

        offer3 = await marketplace.getOffer(3)

        expect(offer3.buyer).to.equal(acc1.address)

        expect(await n721.ownerOf(2)).to.equal(acc1.address)
      })

      // buySale() revert on closed offer
      it("3) it should revert with 'offer is closed' when trying to buy an offer that is closed", async () => {
        await expect(marketplace.buySale(3, { value: ethers.utils.parseEther("1.0") })).to.be.revertedWith("offer is closed")
      })


      // makeOffer() success without previous pending offer
      it("4) it should sucesfully submit an offer", async () => {

        //creates a new sale
        await marketplace.createSale(n721.address, 4, 4)

        await expect(marketplace.connect(acc1).makeOffer(5, { value: ethers.utils.parseEther("2") })).to.changeEtherBalances([acc1.address, marketplace.address], [ethers.utils.parseEther("-2"), ethers.utils.parseEther("2")]);

        let offer5 = await marketplace.getOffer(5)

        expect(offer5.offer).to.not.equal(0)

        expect(offer5.offerAddress).to.equal(acc1.address)
      })

      // makeOffer() success with previous pending offer
      it("5) it should successfuly accept new offer. Offerer should be debited &previous offerer refunded", async () => {
        let offer5 = await marketplace.getOffer(5)

        await expect(marketplace.connect(acc2).makeOffer(5, { value: ethers.utils.parseEther("3") })).to.changeEtherBalances([acc2.address, acc1.address], [ethers.utils.parseEther("-3"), offer5.offer]);

        offer5 = await marketplace.getOffer(5)

        expect(offer5.offer).to.not.equal(0)

        expect(offer5.offerAddress).to.equal(acc2.address)

      })

      // makeOffer() revert on unsufficient amount bided
      it("6) it should revert on new offer lower than previous one", async () => {
        await expect(marketplace.connect(acc2).makeOffer(5, { value: ethers.utils.parseEther("2") })).to.be.revertedWith('offer too low')
      })

      // acceptOffer() success and refund previous bidder
      it("7) it should accept offer send funds to previous owner and transfer NFT to new owner", async () => {
        let offer5 = await marketplace.getOffer(5)

        await expect(marketplace.acceptOffer(5)).to.changeEtherBalances([marketplace.address, owner.address], [ethers.utils.parseEther("-3"), offer5.offer])

        expect(await n721.ownerOf(4)).to.equal(acc2.address)
      })

      // makeOffer() revert on closed offer
      it("8) it should revert new offer if offer is closed", async () => {
        await expect(marketplace.connect(acc2).makeOffer(5, { value: ethers.utils.parseEther("7") })).to.be.revertedWith('offer not available')
      })

      // cancelOffer() should revert on minimum cancelTime not reached
      it("9) it should revert cancelSale() with '48h minimum before cancel'", async () => {
        await expect(marketplace.connect(acc2).makeOffer(2, { value: ethers.utils.parseEther("3") })).to.changeEtherBalances([acc2.address, marketplace.address], [ethers.utils.parseEther("-3"), ethers.utils.parseEther("3")]);

        await expect(marketplace.connect(acc2).cancelOffer(2)).to.be.revertedWith('48h minimum before cancel');
      })

      // cancelOffer() succes and refund of previous offer to bidder
      it("10) it should cancel an offer and refund bider if offer was made", async () => {
        let twodays = 60 * 60 * 24 * 2;

        await ethers.provider.send('evm_increaseTime', [twodays]);

        await ethers.provider.send('evm_mine');

        await expect(marketplace.connect(acc2).cancelOffer(2)).to.changeEtherBalances([marketplace.address, acc2.address], [ethers.utils.parseEther("-3"), ethers.utils.parseEther("3")]);

        let offer2 = await marketplace.getOffer(2)

        expect(offer2.closed).to.equal(false)

        expect(offer2.offer).to.equal(0)
      })
    })
    describe("_Fees_", async ()=> {
      it("1) fees are at 0", async () => {
        expect(await marketplace.connect(acc2).marketPlaceFee()).to.equal(0)
      })

      it("1) setFees revert, not owner", async () => {
        await expect(marketplace.connect(acc2).setFees(2)).to.be.revertedWith('Ownable: caller is not the owner');
      })

      it("2) setFees succes", async () => {
        await marketplace.setFees(2)
        expect(await marketplace.connect(acc2).marketPlaceFee()).to.equal(2)
      })

      it("3) withdrawFees revert, not owner", async () => {
        await expect(marketplace.connect(acc2).withdrawFees()).to.be.revertedWith('Ownable: caller is not the owner');
      })

      it("4) withdrawFees succes", async () => {
        await marketplace.withdrawFees()
      })
    })
    //Setfees() revert on not owner

    // setFees() success

    //successful transaction with fees payout

    // withdrawFees() revert on not owner

    //WithdrawFees() success
  })
})