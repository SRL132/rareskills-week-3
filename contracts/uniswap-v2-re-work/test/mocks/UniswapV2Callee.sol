// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IUniswapV2Callee} from "../../src/interfaces/IUniswapV2Callee.sol";
import {IUniswapV2Pair} from "../../src/interfaces/IPair.sol";
import {IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";

contract UniswapV2Callee is IERC3156FlashBorrower {
    address immutable i_uniswapPair;
    address immutable i_tokenA;
    address immutable i_tokenB;
    constructor(address _uniswapPair, address _tokenA, address _tokenB) {
        i_uniswapPair = _uniswapPair;
        i_tokenA = _tokenA;
        i_tokenB = _tokenB;
    }

    function triggerFlashLoanA(uint256 _amount) external {
        IERC3156FlashLender(i_uniswapPair).flashLoan(
            IERC3156FlashBorrower(address(this)),
            i_tokenA,
            _amount,
            ""
        );
    }

    function triggerFlashLoanB(uint256 _amount) external {
        IERC3156FlashLender(i_uniswapPair).flashLoan(
            IERC3156FlashBorrower(address(this)),
            i_tokenB,
            _amount,
            ""
        );
    }

    /**
     * @dev Receive a flash loan.
     * @param _initiator The initiator of the loan.
     * @param _token The loan currency.
     * @param _amount The amount of tokens lent.
     * @param _fee The additional amount of tokens to repay.
     * @param _data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external override returns (bytes32) {
        IERC20(i_tokenA).approve(i_uniswapPair, _amount + _fee);
        IERC20(i_tokenB).approve(i_uniswapPair, _amount + _fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}
