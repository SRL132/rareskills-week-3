// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {Pair} from "./Pair.sol";

/// @title This contract is a re-implementation of the UniswapV2 Factory contract
/// @author Sergi Roca Laguna
/// @notice This contract is a re-implementation of the UniswapV2 Factory contract
/// @dev This contract is a re-implementation of the UniswapV2 Factory contract for version 0.8.24
contract Factory is IUniswapV2Factory {
    error Factory__NotFeeToSetter();
    error Factory__IdenticalAddresses();
    error Factory__PairAlreadyExists();
    error Factory__ZeroAddress();

    //STORAGE VARIABLES
    address s_feeTo;
    address s_feeToSetter;

    mapping(address token0 => mapping(address token1 => address pair)) s_tokensToPair;

    uint256 s_pairsCounter;

    //FUNCTIONS
    modifier onlyFeeToSetter() {
        if (msg.sender != s_feeToSetter) revert Factory__NotFeeToSetter();
        _;
    }

    /// @param _feeToSetter The address of the fee to setter, which is the only one that can change feeTo
    constructor(address _feeToSetter) {
        s_feeToSetter = _feeToSetter;
    }

    //EXTERNAL FUNCTIONS
    /// @notice This function sets the fee to address
    /// @param _feeTo The address which will receive the fees
    function setFeeTo(address _feeTo) external onlyFeeToSetter {
        s_feeTo = _feeTo;
    }

    /// @notice This function sets the fee to setter address
    /// @param _feeToSetter The address which will be the new fee to setter
    function setFeeToSetter(address _feeToSetter) external onlyFeeToSetter {
        s_feeToSetter = _feeToSetter;
    }

    /// @notice This function creates a new pair
    /// @param _tokenA The address of the first token
    /// @param _tokenB The address of the second token
    /// @return pair The address of the new pair
    function createPair(
        address _tokenA,
        address _tokenB
    ) external returns (address pair) {
        if (_tokenA == _tokenB) {
            revert Factory__IdenticalAddresses();
        }
        (address token0, address token1) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);

        if (token0 == address(0)) {
            revert Factory__ZeroAddress();
        }

        if (s_tokensToPair[token0][token1] != address(0)) {
            revert Factory__PairAlreadyExists();
        }

        bytes32 salt = keccak256(abi.encode(token0, token1));

        pair = address(new Pair{salt: salt}(token0, token1));

        s_tokensToPair[token0][token1] = pair;
        s_tokensToPair[token1][token0] = pair;

        unchecked {
            ++s_pairsCounter;
        }

        emit PairCreated(token0, token1, pair, s_pairsCounter);
    }

    //EXTERNAL VIEW FUNCTIONS
    /// @notice This function returns the address of a pair
    /// @param _tokenA The address of the first token
    /// @param _tokenB The address of the second token
    /// @return pair The address of the pair
    function getPair(
        address _tokenA,
        address _tokenB
    ) external view returns (address pair) {
        return s_tokensToPair[_tokenA][_tokenB];
    }

    /// @notice This function returns the number of pairs
    /// @return The number of pairs
    function allPairsCount() external view returns (uint256) {
        return s_pairsCounter;
    }

    /// @notice This function returns the fee to setter address
    /// @return The address fees will be sent to
    function feeTo() external view override returns (address) {
        return s_feeTo;
    }

    /// @notice This function returns the fee to setter address
    /// @return The address of the fee to setter
    function feeToSetter() external view returns (address) {
        return s_feeToSetter;
    }
}
