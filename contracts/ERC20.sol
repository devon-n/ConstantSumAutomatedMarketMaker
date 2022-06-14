// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Token is ERC20 {

	constructor(string memory name_, string memory symbol_, uint amount_)
	ERC20 (name_, symbol_) {
		_mint(msg.sender, amount_);
	}
}