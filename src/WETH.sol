// SPDX-License-Identifier: UNLICENSED
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

import {Ownable} from "openzeppelin/access/Ownable.sol";

pragma solidity 0.8.21;

contract WETH is ERC20, Ownable {
    constructor() ERC20("WETH", "Wrapped Ether") {
        _mint(msg.sender, 1e6 * 1e18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
