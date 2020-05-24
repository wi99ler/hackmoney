# hackmoney
DiaChain HackMoney

####################################################################################################
migrate --reset

//contracts
let nft = await DiaNFT.deployed()
let won = await Won.deployed()
let market = await Market.deployed()
let funds = await Funds.deployed()

// 0번 계정 운영자, 1번 계정 도매상, 2번 계정 소매상, 3번 계정 투자자
// 1, 2, 3 각각 100000000 배분
let accounts = await web3.eth.getAccounts()
won.transfer(accounts[1], 100000000)
won.transfer(accounts[2], 100000000)
won.transfer(accounts[3], 100000000)
//let balance = await won.balanceOf(accounts[0])
//balance.toNumber()

//1번 계정으로 다이아 NFT 2개 발행
nft.mintDia("Clarity0", "Color0", "Carat0", "Cut0", "GirdleCode0", "Report0", "etc0", accounts[1])
nft.approve()
nft.mintDia("Clarity1", "Color1", "Carat1", "Cut1", "GirdleCode1", "Report1", "etc1", accounts[1])
//nft.getDia(1)

// 3번 계정으로 fund에 100 투자
won.approve(funds.address, 100, {from: accounts[3]})
//won.allowance(accounts[3], funds.address)
funds.save(100, {from: accounts[3]})

// market에 0번 nft를 100만원에 등록한다
nft.approve(market.address, 0, {from: accounts[1]})
market.register(0, 1000000, {from: accounts[1]})
//nft.ownerOf(0)
#####################################################################################################
