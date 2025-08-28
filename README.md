# Foundry Raffle

A decentralized raffle/lottery smart contract built with **Foundry** that uses **Chainlink VRF** (Verifiable Random Function) for provably fair winner selection and **Chainlink Automation** for automated raffle execution.

## 🎯 Overview

This project implements a transparent, automated lottery system on Ethereum where:
- Players can enter by paying an entrance fee
- Winners are selected using Chainlink VRF for true randomness  
- The raffle automatically executes at regular intervals using Chainlink Automation
- All funds are automatically transferred to the winner

## ✨ Features

- **🎲 Provably Fair**: Uses Chainlink VRF v2.5 for verifiable random winner selection
- **⚡ Automated**: Chainlink Automation triggers raffle execution automatically
- **🔒 Secure**: Built with Solidity ^0.8.19 with comprehensive error handling
- **🌐 Multi-Network**: Supports Ethereum Mainnet, Sepolia testnet, and local development
- **🧪 Well-Tested**: Comprehensive test suite with unit and integration tests
- **📊 Transparent**: All raffle states and events are publicly verifiable

## 🏗️ Architecture

### Core Contract: `Raffle.sol`

The main raffle contract includes:

**State Management**:
- `OPEN`: Players can enter the raffle
- `CALCULATING`: Raffle is processing winner selection

**Key Functions**:
- `enterRaffle()`: Players enter by sending the required entrance fee
- `checkUpkeep()`: Chainlink Automation calls this to check if raffle should execute
- `performUpKeep()`: Triggers the winner selection process
- `fulfillRandomWords()`: Callback function that receives random number and selects winner

**Safety Features**:
- Entry fee validation
- Raffle state checks
- Automated upkeep validation
- Secure fund transfer with revert on failure

## 🛠️ Technology Stack

- **Foundry**: Development framework and testing
- **Solidity**: Smart contract language (^0.8.19)
- **Chainlink VRF v2.5**: Verifiable random number generation
- **Chainlink Automation**: Automated contract execution
- **OpenZeppelin**: Security standards and utilities

## 📋 Prerequisites

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## 🚀 Quick Start

### Installation

```bash
git clone https://github.com/BlazedLith/foundry-raffle
cd foundry-raffle
make install
```

### Build

```bash
make build
# or
forge build
```

### Test

```bash
make test
# or  
forge test
```

### Format Code

```bash
make format
# or
forge fmt
```

## 🧪 Testing

The project includes comprehensive tests covering:

**Unit Tests**:
- Raffle initialization
- Entry validation and player management
- State transitions
- Upkeep conditions
- Winner selection and fund distribution
- Event emissions

**Key Test Scenarios**:
- ✅ Raffle initializes in OPEN state
- ✅ Reverts when insufficient entrance fee sent  
- ✅ Correctly records players and emits events
- ✅ Prevents entries when raffle is calculating
- ✅ Validates upkeep conditions (balance, players, time, state)
- ✅ Properly selects winner and transfers funds
- ✅ Resets raffle state after winner selection

Run specific test files:
```bash
forge test --match-path test/unit/RaffleTest.t.sol -vvv
```

## 🌍 Deployment

### Local Development

Start local blockchain:
```bash
make anvil
```

Deploy to local network:
```bash
make deploy
```

### Testnet Deployment

Deploy to Sepolia:
```bash
make deploy-sepolia
```

**Required Environment Variables**:
```bash
SEPOLIA_RPC_URL=your_sepolia_rpc_url
PRIVATE_KEY=your_private_key  
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## ⚙️ Configuration

### Network Configurations

**Sepolia Testnet**:
- Entrance Fee: 0.01 ETH
- Update Interval: 30 seconds  
- VRF Coordinator: `0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B`
- Gas Lane: `0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae`

**Ethereum Mainnet**:
- Entrance Fee: 0.01 ETH
- Update Interval: 30 seconds
- VRF Coordinator: `0x271682DEB8C4E0901D1a1550aD2e64D568E69909`  
- Gas Lane: `0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805`

## 📖 Usage

### For Players

1. **Enter Raffle**: Call `enterRaffle()` with the required entrance fee
2. **Check Status**: View raffle state with `getRaffleState()`
3. **View Winner**: Check `getRecentWinner()` after raffle completes

### For Operators

1. **Monitor Upkeep**: `checkUpkeep()` returns when raffle should execute
2. **Manual Trigger**: Call `performUpKeep()` if automation fails
3. **View Players**: Use `getPlayer(index)` to see all participants

## 🔧 Smart Contract Interface

### Main Functions

```solidity
// Entry point for players
function enterRaffle() external payable

// Chainlink Automation integration  
function checkUpkeep(bytes memory) external view returns (bool, bytes memory)
function performUpKeep(bytes calldata) external

// View functions
function getEntryFee() external view returns (uint256)
function getRaffleState() external view returns (RaffleState) 
function getPlayer(uint256 index) external view returns (address)
function getRecentWinner() external view returns (address)
function getLastTimestamp() external view returns (uint256)
```

### Events

```solidity
event RaffleEntered(address indexed player);
event WinnerPicked(address indexed winner);  
event WinnerRequested(uint256 indexed requestId);
```

## 🚨 Security Considerations

- **Reentrancy Protection**: Uses `call` with proper state management
- **Access Control**: Functions have appropriate visibility modifiers 
- **Input Validation**: All user inputs are validated
- **State Management**: Proper state transitions prevent exploitation
- **Randomness**: Chainlink VRF ensures tamper-proof randomness

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Chainlink](https://chain.link/) for VRF and Automation services
- [Foundry](https://getfoundry.sh/) for the excellent development framework
- [Cyfrin](https://cyfrin.io/) for educational resources and development patterns

---

**⚠️ Disclaimer**: This is a demonstration project. Always conduct thorough testing and auditing before deploying to mainnet with real funds.
