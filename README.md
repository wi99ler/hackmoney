# hackmoney
DiaChain HackMoney

###################################################################################################
migrate --reset

//accounts
let accounts = await web3.eth.getAccounts()

//contracts
let nft = await DiaNFT.deployed()
let won = await Won.deployed()
let market = await Market.deployed()
let funds = await Funds.deployed()

funds.setMarket(market.address)

//0번 계정 운영자, 1번 계정 도매상, 2번 계정 소매상, 3번 계정 투자자

// 1, 2, 3 각각 100,000,000 배분
won.transfer(accounts[1], 100000000)
won.transfer(accounts[2], 100000000)
won.transfer(accounts[3], 100000000)
//let balance = await won.balanceOf(accounts[0])
//balance.toNumber()

//1번 계정으로 다이아 NFT 2개 발행
nft.mintDia("Clarity0", "Color0", "Carat0", "Cut0", "GirdleCode0", "Report0", "etc0", accounts[1])
nft.mintDia("Clarity1", "Color1", "Carat1", "Cut1", "GirdleCode1", "Report1", "etc1", accounts[1])
//nft.getDia(1)

//0번, 3번 계정으로 fund에 10,000,000 투자
won.approve(funds.address, 10000000)
funds.save(10000000)
won.approve(funds.address, 10000000, {from: accounts[3]})
funds.save(10000000, {from: accounts[3]})
//won.allowance(accounts[0], funds.address)
//funds.getAccount(0)

//market에 0번 nft를 1,000,000에 등록
nft.approve(market.address, 0, {from: accounts[1]})
market.register(0, 1000000, {from: accounts[1]})
nft.approve(market.address, 1, {from: accounts[1]})
market.register(1, 500000, {from: accounts[1]})
//nft.ownerOf(0)
//accounts[1]

//2번 계정으로 0번 NFT rent
market.rentDiamond(0, {from: accounts[2]})
//funds.getIOU(0)

//1번 계정으로 0번 NFT를 근거로 유동성 공급 요청
market.claim4liquidity(0, {from:accounts[1]})
//balance = await won.balanceOf(accounts[1])
//balance.toNumber()

//2번 계정으로 1번 NFT rent
market.rentDiamond(1, {from: accounts[2]})
//funds.getIOU(1)

//2번 계정으로 1번 NFT 구매 확정
won.approve(market.address, 550000, {from: accounts[2]})
market.confirmPurchase(1, {from:accounts[2]})
//won.getAccount(1)
###################################################################################################

