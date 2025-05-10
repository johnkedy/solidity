# SimpleStorage Smart Contract

A basic Ethereum smart contract written in Solidity that demonstrates how to store, retrieve, and map user data on the blockchain. This contract is ideal for beginners learning how Web3 and Solidity work together.

---

## 📜 Contract Overview

This contract allows you to:
- Store a single favorite number.
- Add people with a name and their favorite number.
- Retrieve the stored favorite number.
- Access a mapping of names to favorite numbers.

---

## 🧱 Contract Structure

### State Variables
- `uint256 favoriteNumber`  
  Stores a single number set by users.

- `People[] public people`  
  An array to store multiple people's names and favorite numbers.

- `mapping(string => uint256) public nameToFavoriteNumber`  
  A mapping to retrieve a person's favorite number by their name.

---

## 🔧 Functions

### `store(uint256 _favoriteNumber)`
Stores a new favorite number.

### `retrieve() public view returns (uint256)`
Returns the currently stored favorite number.

### `addPerson(string memory _name, uint256 _favoriteNumber)`
Adds a new person to the `people` array and updates the `nameToFavoriteNumber` mapping.

---

## 🛠 Requirements

- Solidity `0.8.8`
- Compatible with tools like:
  - Remix IDE
  - Hardhat or Truffle (for testing/deployment)
  - Web3.js or Ethers.js (for frontend integration)

---

## 🚀 Deployment

1. Use Remix or your preferred development environment.
2. Compile with **Solidity 0.8.8**.
3. Deploy the contract to a local or test network.
4. Interact with it via Web3 frontend or Remix UI.

---

## 📝 License

This project is licensed under the MIT License.
