import hardhat from 'hardhat';
import config from '../src/config.js';
const { ethers } = hardhat;

export const formatTokenUri = (data) => {
  return 'data:application/json;base64,' + btoa(JSON.stringify(data));
};

const getContractInstance = async (privateKey) => {
  const provider = new ethers.JsonRpcProvider(config.JSON_RPC_URL);
  const signer = new ethers.Wallet(privateKey, provider);
  const contract = await ethers.getContractAt('BaseContract', config.CONTRACT_ADDRESS, signer);
  return contract;
};

const createPublicChallenge = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  const challengePayload = {
    _challengeName: 'Challenge #1',
    _startDate: 1713456975,
    _endDate: 1716048975,
    _totalDays: 30,
    _stakedAmount: ethers.parseEther('0.001'),
    _participantsLimit: 25,
    _goal: 50,
    _visibility: 0,
  };

  const transaction = await contract.createChallenge(
    challengePayload._challengeName,
    challengePayload._startDate,
    challengePayload._endDate,
    challengePayload._totalDays,
    challengePayload._stakedAmount,
    challengePayload._participantsLimit,
    challengePayload._goal,
    challengePayload._visibility,
    '',
    { value: challengePayload._stakedAmount }
  );

  await transaction.wait();
};

const createPrivateChallenge = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  const challengePayload = {
    _challengeName: 'Challenge #2',
    _startDate: 1713456975,
    _endDate: 1716048975,
    _totalDays: 30,
    _stakedAmount: ethers.parseEther('0.0001'),
    _participantsLimit: 5,
    _goal: 50,
    _visibility: 1,
    _passKey: 'MyPassKey',
  };

  const transaction = await contract.createChallenge(
    challengePayload._challengeName,
    challengePayload._startDate,
    challengePayload._endDate,
    challengePayload._totalDays,
    challengePayload._stakedAmount,
    challengePayload._participantsLimit,
    challengePayload._goal,
    challengePayload._visibility,
    challengePayload._passKey,
    { value: challengePayload._stakedAmount }
  );

  await transaction.wait();
};

const joinPublicChallenge = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  const transaction = await contract.joinPublicChallenge(0, { value: ethers.parseEther('1') });
  await transaction.wait();
};

const joinPrivateChallenge = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  const transaction = await contract.joinPrivateChallenge(1, 'MyPassKey', { value: ethers.parseEther('2') });
  await transaction.wait();
};

const getUserChallenges = async (privateKey, userKey) => {
  const contract = await getContractInstance(privateKey);
  const challenges = await contract.getUserChallenges(userKey);
  console.log(challenges);
};

const getPublicChallenges = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  const challenges = await contract.publicChallenges();
  console.log(challenges);
};

const getParticipants = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  const participants = await contract.getParticipants(0);
  console.log(participants);
};

const dailyCheckIn = async (privateKey, userAddress, challengeId, stepCount) => {
  const contract = await getContractInstance(privateKey);
  await contract.dailyCheckIn(userAddress, challengeId, stepCount);
};

const decideWinners = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  await contract.decideWinners(0);
  console.log('Winners decided successfully');
};

const getContractBalance = async (privateKey) => {
  const provider = new ethers.JsonRpcProvider(config.JSON_RPC_URL);
  const balance = await provider.getBalance(config.CONTRACT_ADDRESS);
  console.log(`Contract balance: ${ethers.formatEther(balance)} ETH`);
};

const mintNft = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  const tokenMetadata = {
    name: '#1 | Days: 25',
    description: 'Staked-Steps | Marathon 24',
    image: 'imageIpfsUrl',
  };
  const tokenUri = formatTokenUri(tokenMetadata);
  await contract.mintToken('', 0, tokenUri);
};

const getChallengeStakeAmount = async (privateKey) => {
  const contract = await getContractInstance(privateKey);
  const res = await contract.getChallengeStakeAmount('0');
  console.log(res);
};

try {
  const privateKey1 = '';
  const privateKey2 = 'a6e7dc0e2f08f5fa30a21976eca471e05fb31e816572ee39bd0b6c9ebbe0a001';
  const privateKey3 = '';
  await createPublicChallenge(privateKey2);
  // await joinPublicChallenge(privateKey2);
  // await createPrivateChallenge(privateKey2);
  // await joinPrivateChallenge(privateKey2);
  // await joinPrivateChallenge(privateKey3);

  // await dailyCheckIn(privateKey1, '', 0, 10100);
  // await dailyCheckIn(privateKey1, '', 0, 100);
  // await dailyCheckIn(privateKey1, '', 1, 12345);
  // await dailyCheckIn(privateKey1, '', 1, 12000);
  // await dailyCheckIn(privateKey3, 1, 23459);
  await getPublicChallenges(privateKey2);
  // await decideWinners(privateKey1)
  // await mintNft(privateKey1);
  // await getParticipants(privateKey1);
  // await getUserChallenges(privateKey1, '');
  // await getContractBalance(privateKey1)
  // await sendEth(privateKey1)
  // await getContractBalance(privateKey1)
} catch (e) {
  console.log(e);
}
