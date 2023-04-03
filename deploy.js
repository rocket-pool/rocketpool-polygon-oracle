require('dotenv').config();

const process = require('process');
const ethers = require('ethers');

const RocketPolygonPriceMessenger = require('./out/RocketPolygonPriceMessenger.sol/RocketPolygonPriceMessenger.json');
const RocketPolygonPriceOracle = require('./out/RocketPolygonPriceOracle.sol/RocketPolygonPriceOracle.json');
const RocketBalancerRateProvider = require('./out/RocketBalancerRateProvider.sol/RocketBalancerRateProvider.json');

const polygonProvider = new ethers.providers.JsonRpcProvider(process.env.POLYGON_RPC);
const polygonWallet = ethers.Wallet.fromMnemonic(process.env.POLYGON_MNEMONIC).connect(polygonProvider);

const ethereumProvider = new ethers.providers.JsonRpcProvider(process.env.ETHEREUM_RPC);
const ethereumWallet = ethers.Wallet.fromMnemonic(process.env.ETHEREUM_MNEMONIC).connect(ethereumProvider);

const ethTxOverrides = {
  maxFeePerGas: ethers.utils.parseUnits('20', 'gwei'),
  maxPriorityFeePerGas: ethers.utils.parseUnits('1.5', 'gwei'),
}

const polygonTxOverrides = {
  maxFeePerGas: ethers.utils.parseUnits('200', 'gwei'),
  maxPriorityFeePerGas: ethers.utils.parseUnits('55', 'gwei'),
}

async function deploy() {
  console.log(`Ethereum deployer address: ${ethereumWallet.address}`);
  console.log(`Polygon deployer address: ${polygonWallet.address}`);

  // Create factories
  const messengerFactory = new ethers.ContractFactory(RocketPolygonPriceMessenger.abi,
      RocketPolygonPriceMessenger.bytecode.object).connect(ethereumWallet);
  const oracleFactory = new ethers.ContractFactory(RocketPolygonPriceOracle.abi,
      RocketPolygonPriceOracle.bytecode.object).connect(polygonWallet);
  const balancerProviderFactory = new ethers.ContractFactory(RocketBalancerRateProvider.abi,
      RocketBalancerRateProvider.bytecode.object).connect(polygonWallet);

  // Deploy
  console.log('Deploying messenger');
  const messenger = await messengerFactory.deploy(process.env.ROCKET_STORAGE, process.env.POLYGON_CHECKPOINT_MANAGER_L1,
      process.env.POLYGON_FX_ROOT_L1, ethTxOverrides);
  console.log(`Messenger address: ${messenger.address}`);

  console.log('Deploying oracle');
  const oracle = await oracleFactory.deploy(process.env.POLYGON_FX_CHILD_L2, polygonTxOverrides);
  console.log(`Oracle address: ${oracle.address}`);

  // Setup tunnel
  console.log('Setting up tunnel');
  await messenger.setFxChildTunnel(oracle.address, ethTxOverrides);
  await oracle.setFxRootTunnel(messenger.address, polygonTxOverrides);
  console.log('Tunnel setup.');

  // Deploy balancer rate provider wrapper
  console.log('Deploying balancer wrapper');
  const balancerWrapper = await balancerProviderFactory.deploy(oracle.address, polygonTxOverrides);
  console.log(`Balancer wrapper address: ${balancerWrapper.address}`);

  console.log('Deployment complete.');

  process.exit(0);
}

deploy();
