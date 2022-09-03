const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Marketplace", function () {
  before(async function () {
    const [owner, acc1, acc2, acc3] = await ethers.getSigners();
    const initialMint = 20;

    global.owner  = owner;
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

  it("it should correctly test 721", async () =>{
    expect(await global.n721.name()).to.equal("721test")

    expect(await global.n721.symbol()).to.equal("721")

    expect(await global.n721.totalSupply()).to.equal(3)

    await global.n721.mint(3)

    expect(await global.n721.totalSupply()).to.equal(6)
  })

  it("it should correctly test 721a", async () =>{
    expect(await global.n721A.name()).to.equal("721Atest")

    expect(await global.n721A.symbol()).to.equal("721a")

    expect(await global.n721A.totalSupply()).to.equal(20)

    await global.n721A.mint(5)

    expect(await global.n721A.totalSupply()).to.equal(25)
  })

  it("it should correctly test 1155", async () =>{
    expect(await global.n1155.uri(0)).to.not.equal("")

    expect(await global.n1155.totalSupply(0)).to.equal(20)

    await global.n1155.mint(0, 10)

    expect(await global.n1155.totalSupply(0)).to.equal(30)
  })

  it("marketplace should have no offers registered", async () => {
    let offer1 = await global.marketplace.getOffer(0)

    expect(offer1.seller).to.equal("0x0000000000000000000000000000000000000000")
  })

  it("ERC721 - creating a sale order without approval should revert with 'ERC721: caller is not token owner nor approved'", async () => {
    expect( await global.n721.ownerOf(0)).to.equal(global.owner.address)
  
    await expect( global.marketplace.createSale(global.n721.address, 0, 1)).to.be.revertedWith('ERC721: caller is not token owner nor approved')
  })

  it("ERC721 - it should create a sale and offer1 have seller, contract address, price , tokenId, standard be ERC721 and closed be false", async () => {
    expect( await global.n721.ownerOf(0)).to.equal(global.owner.address)
    await global.n721.setApprovalForAll(global.marketplace.address, true)
    await global.marketplace.createSale(global.n721.address, 0, 1)

    let offer1 = await global.marketplace.getOffer(0)
    expect(offer1.seller).to.equal(global.owner.address)

    expect(offer1.contractAddress).to.equal(global.n721.address)

    expect(offer1.closed).to.equal(false)

    expect(offer1.price).to.equal(1)

    expect(offer1.tokenId).to.equal(0)

    expect(offer1.standard).to.equal("ERC721")
  })

  it("ERC1155 - creating a sale order without approval should revert with 'ERC1155: caller is not token owner nor approved'", async () => {
    expect( await global.n1155.balanceOf(global.owner.address, 0)).to.not.equal(0)
  
  await expect( global.marketplace.createSale(global.n1155.address, 0, 1)).to.be.revertedWith('ERC1155: caller is not token owner nor approved')
  })

  it("ERC1155 - it should create a sale and offer2 have seller, contract address, price , tokenId, standard be ERC1155 and closed be false", async () => {
    expect( await global.n1155.balanceOf(global.owner.address, 0)).to.not.equal(0)

    await global.n1155.setApprovalForAll(global.marketplace.address, true)
    await global.marketplace.createSale(global.n1155.address, 0, 1)

    let offer2 = await global.marketplace.getOffer(1)
    expect(offer2.seller).to.equal(global.owner.address)

    expect(offer2.contractAddress).to.equal(global.n1155.address)

    expect(offer2.closed).to.equal(false)

    expect(offer2.price).to.equal(1)

    expect(offer2.tokenId).to.equal(0)

    expect(offer2.standard).to.equal("ERC1155")
  })

  it("should create a sale & emit a 'Transfer' event & a 'SaleCreated' event", async () => {
    expect( await global.n721.ownerOf(1)).to.equal(global.owner.address)
    await global.n721.setApprovalForAll(global.marketplace.address, true)
    await expect(global.marketplace.createSale(global.n721.address, 1, 1)).to.emit(global.n721, 'Transfer').withArgs(global.owner.address, global.marketplace.address,1)
    await expect(global.marketplace.createSale(global.n721.address, 2, 1)).to.emit(global.marketplace, 'SaleCreated').withArgs(3, global.owner.address,2, global.n721.address,1)
  })

  it("should revert with 'not owner' for a NFT erc721 and erc1155 ", async () => {

  })

  //create sale revert on non recognized standard

  //Modify sale

  //Modify revert

  //cancelSale success with offer & without offer

  //cancelSale revert on closed offer

  //buySale success

  //buySale revert on wrong ether amount
});
