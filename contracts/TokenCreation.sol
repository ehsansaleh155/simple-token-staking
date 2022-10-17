// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("SToken", "TKS") {
        _mint(msg.sender, initialSupply);
    }
}

contract RToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("RToken", "TKR") {
        _mint(msg.sender, initialSupply);
    }
}
