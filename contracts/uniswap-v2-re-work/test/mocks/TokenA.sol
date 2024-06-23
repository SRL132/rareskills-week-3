// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@solady/tokens/ERC20.sol";

contract TokenA is ERC20 {
    constructor() ERC20() {}

    /// @dev Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return "Token A";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return "TA";
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
