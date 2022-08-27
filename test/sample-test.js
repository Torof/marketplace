const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Marketplace", function () {
  before(async function () {
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const marketplace = await Marketplace.deploy();
    await marketplace.deployed();
    global.marketplace = marketplace

    const N721 = await ethers.getContractFactory("NFT721");
    const n721 = await N721.deploy();
    await n721.deployed();
    global.n721 = n721

    const N721A = await ethers.getContractFactory("NFT721A");
    const n721A = await N721A.deploy();
    await n721A.deployed();
    global.n721A = n721A
  });

  it("should correctly test 721", async () =>{
    expect(await global.n721.name()).to.equal("721test")
    expect(await global.n721.symbol()).to.equal("721")
    expect(await global.n721.totalSupply()).to.equal(3)
  })

  it("should correctly test 721a", async () =>{
    expect(await global.n721A.name()).to.equal("721Atest")
    expect(await global.n721A.symbol()).to.equal("721a")
    expect(await global.n721A.totalSupply()).to.equal(20)
  })

  it("marketplace should have no offers registered", async () => {
    let offer1 = await global.marketplace.getOffer(0)
    expect(offer1.tokenIds.length).to.equal(0)
  })

  it("should create a sale and offer 1 have seller, contract address, price , tokenIds and closed be false", async () => {
    console.log(global.n721.address)
    console.log(global.marketplace.address)
    console.log(await global.n721.ownerOf(0))
    await global.marketplace.createSale(global.n721.address, [0], 1)
    // console.log(await global.marketplace.getOffer(0))
  })
});
