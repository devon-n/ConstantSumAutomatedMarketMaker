const { expect } = require("chai")
const { ethers } = require("hardhat")

/* Variables */
const TOKENS_TO_MINT = 100000
let owner
let csamm
let token0
let token1

describe("Constant Sum Automated Market", function () {

  
  beforeEach(async function() {
    [owner] = await ethers.getSigners()
    // Get Contracts
    const CSAMM = await ethers.getContractFactory("CSAMM")
    const Token = await ethers.getContractFactory("Token")

    // Deploy Contracts
    token0 = await Token.deploy('token0', 'TKN0', TOKENS_TO_MINT)
    token1 = await Token.deploy('token1', 'TKN1', TOKENS_TO_MINT)

    await token0.deployed()
    await token1.deployed()

    csamm = await CSAMM.deploy(token0.address, token1.address)
    await csamm.deployed()

    // Approve contract to spend tokens
    await token0.approve(csamm.address, TOKENS_TO_MINT)
    await token1.approve(csamm.address, TOKENS_TO_MINT)
  })

  it("Should add, swap and remove liquidity", async function () {

    /* Add Liquidity */
    await csamm.addLiquidity(TOKENS_TO_MINT/2, TOKENS_TO_MINT/2)

    // Check shares and reserves
    const shares = await csamm.balanceOf(owner.address)
    let reserves0 = await csamm.reserve0()
    let reserves1 = await csamm.reserve1()
    let balanceOf = await csamm.balanceOf(owner.address)

    expect(shares).to.equal(balanceOf)
    expect(reserves0).to.equal(TOKENS_TO_MINT/2)
    expect(reserves1).to.equal(TOKENS_TO_MINT/2)

    /* Swap Tokens */
    await csamm.swap(token0.address, TOKENS_TO_MINT/2)

    let token0bal = await token0.balanceOf(owner.address)
    let token1bal = await token1.balanceOf(owner.address)
    
    reserves0 = await csamm.reserve0()
    reserves1 = await csamm.reserve1()
    balanceOf = await csamm.balanceOf(owner.address)

    expect(token0bal).to.equal(0)
    expect(token1bal).to.equal(TOKENS_TO_MINT)

    /* Remove Liquididty */
    await csamm.removeLiquidity(balanceOf)

    reserves0 = await csamm.reserve0()
    reserves1 = await csamm.reserve1()
    balanceOf = await csamm.balanceOf(owner.address)

    token0bal = await token0.balanceOf(owner.address)
    token1bal = await token1.balanceOf(owner.address)

    const totalSupply = await csamm.totalSupply()

    expect(reserves0).to.equal(0)
    expect(reserves1).to.equal(0)
    expect(balanceOf).to.equal(0)

    expect(token0bal).to.equal(TOKENS_TO_MINT)
    expect(token1bal).to.equal(TOKENS_TO_MINT)

    expect(totalSupply).to.equal(0)
  })
})
