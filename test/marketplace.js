const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("@nomicfoundation/hardhat-network-helpers");

///TODO: tests for fees (ETH + WETH)
///ALERT: reorganize, list and track test better
///TODO: write test for multiple orders with ERC1155 same token id

describe("Marketplace", function () {
  before(async function () {
    const [owner, acc1, acc2, acc3] = await ethers.getSigners();
    const initialMint = 20;

    global.owner = owner;
    global.acc1 = acc1;
    global.acc2 = acc2;
    global.acc3 = acc3;

    const weth = await ethers.getContractFactory("WETH");
    const WETH = await weth.deploy();
    await WETH.deployed();
    global.WETH = WETH

    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await Marketplace.deploy(WETH.address);
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

    let summary = async (num) => {
      let orders = [];
      let offers = [];
      let offer = {};
      for(i = 1; i <= num; i++){
        let order = await marketplace.getSaleOrder(i)
        orders.push(order)
      }
      console.log("number of offers: " + num)
      console.log(orders)
      for(i= 0; i < orders.length; i++){
        if(orders[i].offers.length > 0) console.log(orders[i].offers)
      }
    }

    global.summary = summary
  });

  describe("¤¤NFT Marketplace¤¤",async function () {

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
      it("1)  it should have no offers registered yet", async () => {
        let saleOrder1 = await marketplace.getSaleOrder(1)

        expect(saleOrder1.seller).to.equal("0x0000000000000000000000000000000000000000")
      })

      // revert on direct NFT transfer from owner (with safeTransferFrom)
      it("2)  it should revert on direct transfer from owner", async () => {
        await expect( n721["safeTransferFrom(address,address,uint256)"](owner.address, marketplace.address, 1)).to.be.revertedWith('direct transfer not allowed')
      })

        //revert on direct transfer from approved address (with safeTransferFrom)
      it("3)  it should revert on direct transfer from approved sender", async () => {
        await n721.approve(acc2.address, 2)
        await expect( n721.connect(acc2)["safeTransferFrom(address,address,uint256)"](owner.address, marketplace.address, 2)).to.be.revertedWith('direct transfer not allowed')
      })

      // createSale() revert on not approved for {ERC721}
      it("4)  it should revert with 'ERC721: caller is not token owner nor approved' when a submitting a new sale order without approval - ERC721 -", async () => {
        expect(await n721.ownerOf(1)).to.equal(owner.address)

        await expect(marketplace.createSale(n721.address, 1, 1)).to.be.revertedWith('ERC721: caller is not token owner nor approved')
      })

      // createSale() success and parameters verifications for {ERC721}
      it("5)  it should create a sale and saleOrder1 have seller, contract address, price , tokenId, standard be ERC721 and closed be false - ERC721 - ", async () => {
        expect(await n721.ownerOf(1)).to.equal(owner.address)

        await n721.setApprovalForAll(marketplace.address, true)

        await marketplace.createSale(n721.address, 1, ethers.utils.parseEther("1"))

        let saleOrder1 = await marketplace.getSaleOrder(1)
        expect(saleOrder1.seller).to.equal(owner.address)

        expect(saleOrder1.contractAddress).to.equal(n721.address)

        expect(saleOrder1.closed).to.equal(false)

        expect(saleOrder1.price).to.equal(ethers.utils.parseEther("1"))

        expect(saleOrder1.tokenId).to.equal(1)

        expect(saleOrder1.standard).to.equal("ERC721")
      })

      // createSale() revert on not approved for {ERC721}
      it("6)  it should revert with 'ERC1155: caller is not token owner nor approved' when a submitting a new sale order without approval - ERC1155 -", async () => {
        expect(await n1155.balanceOf(owner.address, 1)).to.not.equal(0)

        await expect(marketplace.createSale(n1155.address, 1, 1)).to.be.revertedWith('ERC1155: caller is not token owner nor approved')
      })

      // createSale() success and parameters verifications for {ERC1155}
      it("7)  it should create a sale and saleOrder2 have seller, contract address, price , tokenId, standard be ERC1155 and closed be false, - ERC1155 - ", async () => {
        expect(await n1155.balanceOf(owner.address, 1)).to.not.equal(0)

        await n1155.setApprovalForAll(marketplace.address, true)

        await marketplace.createSale(n1155.address, 1, ethers.utils.parseEther("1"))

        let saleOrder2 = await marketplace.getSaleOrder(2)

        expect(saleOrder2.seller).to.equal(owner.address)

        expect(saleOrder2.contractAddress).to.equal(n1155.address)

        expect(saleOrder2.closed).to.equal(false)

        expect(saleOrder2.price).to.equal(ethers.utils.parseEther("1"))

        expect(saleOrder2.tokenId).to.equal(1)

        expect(saleOrder2.standard).to.equal("ERC1155")
      })


      // succesful 'Transfer' & 'SaleCreated' event for createSale()
      it("8)  it should create a sale & emit a 'Transfer' event & a 'SaleCreated' event", async () => {
        expect(await n721.ownerOf(2)).to.equal(owner.address)

        await n721.setApprovalForAll(marketplace.address, true)

        await expect(marketplace.createSale(n721.address, 2, ethers.utils.parseEther("1"))).to.emit(n721, 'Transfer').withArgs(owner.address, marketplace.address, 2)

        await expect(marketplace.createSale(n721.address, 3, ethers.utils.parseEther("1"))).to.emit(marketplace, 'SaleCreated').withArgs(4, owner.address, 3, n721.address, "ERC721", ethers.utils.parseEther("1"))
      })

      console.log("blob")

      // createSale() revert when trying to sell a {ERC721} NFT not owned
      it("9)  it should revert with custom error 'notOwner' when an address creates a sale for a NFT (erc721) it doesn't own ", async () => {
        await n721.connect(acc1).mint(2)

        expect(await n721.ownerOf(6)).to.not.equal(acc2.address)

        await expect(marketplace.connect(acc2).createSale(n721.address, 6, 2)).to.be.revertedWithCustomError(marketplace,'notOwner')
      })

      // createSale() revert when trying to sell a {ERC1155} NFT not owned
      it("10)  it should revert with custom error 'notOwner' when an address creates a sale for a NFT (erc1155) it doesn't own ", async () => {
        await n1155.connect(acc1).mint(1, 5)

        expect(await n1155.balanceOf(acc2.address, 1)).to.equal(0)

        await expect(marketplace.connect(acc2).createSale(n1155.address, 1, 2)).to.be.revertedWithCustomError(marketplace,'notOwner')
      })

      //TODO: create sale revert on non recognized standard

      // modifySale() revert on not owner modification
      it("11) it should revert with 'not owner' when an other address than the seller tries to modify it ", async () => {
        await expect(marketplace.connect(acc1).modifySale(1, 2)).to.be.revertedWithCustomError(marketplace,'notOwner')
      })


      // modifySale success
      it("12) it should have owner of a sale able to modify it", async () => {
        let price1Tx = await marketplace.getSaleOrder(1)

        await (marketplace.modifySale(1, 2))

        let price2Tx = await marketplace.getSaleOrder(1)

        expect(price1Tx.price).to.not.equal(price2Tx.price)
      })


      // cancelSale success with offer & event
      it("13) it should successfully cancel a sale order and send a SaleCanceled event", async () => {
        let saleOrder1 = await marketplace.getSaleOrder(1)

        expect(saleOrder1.closed).to.equal(false)

        await expect(marketplace.cancelSale(1)).to.emit(marketplace, 'SaleCanceled').withArgs(1)

        saleOrder1 = await marketplace.getSaleOrder(1)

        expect(saleOrder1.closed).to.equal(true)
      })

      // cancelSale() revert on offer closed
      it("14) it should revert if sale is already closed", async () => {
        let saleOrder1 = await marketplace.getSaleOrder(1)

        expect(saleOrder1.closed).to.equal(true)

        await expect(marketplace.cancelSale(1)).to.be.revertedWithCustomError(marketplace, 'offerClosed')
      })

      // cancelSale() revert on not owner
      it("15) it should revert with 'not owner' if not the owner tries to cancel the sale", async () => {
        await expect(marketplace.connect(acc1).cancelSale(2)).to.be.revertedWithCustomError(marketplace, 'notOwner')
      })

      it("summary:", async () => {
        
        let numOfOrders = await marketplace.marketOffersNonce() -1
        
        summary(numOfOrders)
      })
    })

    await describe("_Offers_ -Buy sale, make offer, cancel offer, accept offer", async () => {

      // buySale() revert wrong amount
      it("1)  it should revert if not right amount of ether is supplied", async () => {
        await expect(marketplace.connect(acc1).buySale(2, { value: ethers.utils.parseEther("0.5") })).to.be.revertedWith('not the right amount')
      })

      // buySale() success
      it("2)  it should succesfully buy sale order 1 and be new owner of NFT", async () => {
        let saleOrder3 = await marketplace.getSaleOrder(3)

        expect(saleOrder3.seller).to.equal(owner.address)

        expect(saleOrder3.buyer).to.equal("0x0000000000000000000000000000000000000000")



        let snapshot = await helpers.takeSnapshot()
        await expect(marketplace.connect(acc1).buySale(3, { value: ethers.utils.parseEther("1.0") })).to.emit(marketplace, "SaleSuccessful").withArgs(3, saleOrder3.seller, acc1.address, saleOrder3.price)

        saleOrder3 = await marketplace.getSaleOrder(3)

        expect(saleOrder3.buyer).to.equal(acc1.address)
        expect(saleOrder3.closed).to.equal(true)
        expect(await n721.ownerOf(saleOrder3.tokenId)).to.equal(acc1.address)

        await snapshot.restore()
        await expect(marketplace.connect(acc1).buySale(3, { value: ethers.utils.parseEther("1.0") })).to.changeEtherBalances([acc1, owner], [ethers.utils.parseEther("-1.0"), ethers.utils.parseEther("1.0")]);
      })

      // buySale() revert on closed offer
      it("3)  it should revert with 'offer is closed' when trying to buy an offer that is closed", async () => {
        await expect(marketplace.buySale(3, { value: ethers.utils.parseEther("1.0") })).to.be.revertedWithCustomError(marketplace, "offerClosed")
      })

      //TODO: makeOffer() revert 'with not enough balance'

      //TODO: makeoffer() revert not enough allowance

      // makeOffer() success
      it("4)  it should sucesfully submit an offer", async () => {
        await WETH.mint(acc1.address, 100)
        await WETH.connect(acc1).approve(marketplace.address, 10)
        //creates a new sale
        await marketplace.createSale(n721.address, 4, 4)

        await marketplace.connect(acc1).makeOffer(5, 2 , 2 * 60 * 60)

        let saleOrder5 = await marketplace.getSaleOrder(5)
        let offer1 = saleOrder5.offers[0]

        expect(offer1.amount).to.not.equal(0)

        expect(offer1.sender).to.equal(acc1.address)
      })

      // makeOffer() success with previous pending offer
      it("5)  it should successfuly accept new offer. ", async () => {
        await WETH.mint(acc2.address, 100)
        await WETH.connect(acc2).approve(marketplace.address, 10000000000)
        await marketplace.connect(acc2).makeOffer(5, 5, 2*60*60)

        let saleOrder5 = await marketplace.getSaleOrder(5)
        let offer2 = saleOrder5.offers[1]
        expect(offer2.amount).to.not.equal(0)

        expect(offer2.sender).to.equal(acc2.address)

      })

      // makeOffer() revert on unsufficient amount bided
      it("6)  it should revert on new offer if amount is zero", async () => {
        await expect(marketplace.connect(acc2).makeOffer(5, 0, 2*60*60)).to.be.revertedWith("amount can't be zero")
      })

      // acceptOffer() revert if not owner
      it("7) it should revert acceptOffer() if caller is not the owner", async () => {
        await expect(marketplace.connect(acc2).acceptOffer(5,1)).to.be.revertedWithCustomError(marketplace, "notOwner")
      })

      //TODO: acceptOffer() revert if offer expired

      //TODO: acceptOffer() revert if sender not enough balance

      // acceptOffer() success
      it("8)  it should accept offer send funds to seller and transfer NFT to new owner", async () => {
        await WETH.connect(acc2).approve(marketplace.address, 10000000000000)

        await expect(marketplace.acceptOffer(5,1)).to.changeTokenBalance(
          WETH,
          owner,
          5
        );

        expect(await n721.ownerOf(4)).to.equal(acc2.address)
      })

      // makeOffer() revert on closed offer
      it("9)  it should revert new offer if offer is closed", async () => {
        await WETH.mint(acc2.address, 100)
        await WETH.connect(acc2).approve(marketplace.address, 10)
        await expect(marketplace.connect(acc2).makeOffer(5, 1, 5 * 60 * 60)).to.be.revertedWithCustomError(marketplace, 'offerClosed')
      })

      // cancelOffer() succes
      it("10)  it should cancel pending offer and offer array be empty", async () => {

        await marketplace.connect(acc2).makeOffer(2,3, 5*60*60) ;

        let saleOrder2 = await marketplace.getSaleOrder(2)

        expect(saleOrder2.offers[0].sender).to.equal(acc2.address)

        

        await marketplace.connect(acc2).cancelOffer(2,0)

        saleOrder2 = await marketplace.getSaleOrder(2)

        expect(saleOrder2.closed).to.equal(false)
        expect(saleOrder2.offers[0]).to.equal(undefined)
      })

      it("summary", async () =>  {
        let numOfOrders = await marketplace.marketOffersNonce() -1
        
        summary(numOfOrders)
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
        await expect(marketplace.connect(acc2).withdrawEthFees()).to.be.revertedWith('Ownable: caller is not the owner');
      })

      //Check ifowner balance is updated with fee (2% of 1 eth) and market place minus fees
      it("4) withdrawFees succes", async () => {
        await expect(marketplace.connect(acc1).buySale(4, { value: ethers.utils.parseEther("1") })).to.changeEtherBalances([acc1.address, owner.address], [ethers.utils.parseEther("-1"), ethers.utils.parseEther("0.98")]);
        await expect(marketplace.withdrawEthFees()).to.changeEtherBalances([marketplace.address, owner.address], [ethers.utils.parseEther("-0.02"), ethers.utils.parseEther("0.02")]);
      })
    })
  })
})