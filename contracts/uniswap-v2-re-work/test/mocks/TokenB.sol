// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@solady/tokens/ERC20.sol";

contract TokenB is ERC20 {
    constructor() ERC20() {}

    /// @dev Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return "Token B";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return "TB";
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
