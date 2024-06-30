// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {ReentrancyGuard} from "@solady/utils/ReentrancyGuard.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Callee} from "./interfaces/IUniswapV2Callee.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC3156FlashLender} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@solady/utils/FixedPointMathLib.sol";
import "./libraries/UQ112x112.sol";

/// @title Re-implementation of UniswapV2 Pair
/// @author Sergi Roca Laguna
/// @notice This contract is a re-implementation of the UniswapV2 Pair contract that replaces the Uniswapv2 router
/// @dev The contract is a re-implementation of the UniswapV2 Pair contract that assumes the user will interact with directly, with no need for router, the followed pattern is external functions that do the transfers and validations and call internal functions that do the calculations and updates
contract Pair is ERC20, ReentrancyGuard, IERC3156FlashLender {
    using FixedPointMathLib for uint256;
    using UQ112x112 for uint224;

    //ERRORS
    error Pair__InsufficientInputAmount();
    error Pair__InsufficientOutputAmount();
    error Pair__InsufficientLiquidity();
    error Pair__TransferFailed();
    error Pair__NewBalanceCannotBeLessThanKLast();
    error Pair__BurnZeroAmount();
    error Pair__MintZeroAmount();
    error Pair__NotFactory();
    error Pair__AmountInOverLimit();
    error Pair__InvalidToken();
    error Pair__MaxFlashLoanAmountExceeded();
    error Pair__DeadlinePassed();
    error Pair__InvalidOnFlashLoanReturn();

    //STORAGE
    address public immutable i_factory;
    address public immutable i_token0;
    address public immutable i_token1;

    uint112 private s_reserve0; // uses single storage slot, accessible via getReserves
    uint112 private s_reserve1; // uses single storage slot, accessible via getReserves
    uint32 private s_blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public s_price0CumulativeLast;
    uint256 public s_price1CumulativeLast;

    uint256 public s_kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    //CONSTANTS
    uint256 constant FEE = 3; // 0.3% fee
    uint256 constant FEE_DENOMINATOR = 1000;
    uint256 constant FEE_FACTOR = 997; // 0.3% fee
    //Minimum liquidity used to protect against inflation attacks (first minter getting 100% etc)
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint256 public constant MAX_FLASH_LOAN = 1000;
    uint256 public constant FLASH_FEE = 1;
    uint256 public constant FLASH_FEE_DENOMINATOR = 100;

    //STRUCTS
    struct ReceiverAndDeadline {
        address receiver;
        uint256 deadline;
    }

    struct SwapCache {
        uint256 amount0Out;
        uint256 amount1Out;
        uint112 referenceReserveIn;
        uint112 referenceReserveOut;
        address tokenIn;
    }

    struct MinAmounts {
        uint256 amount0;
        uint256 amount1;
    }

    //EVENTS
    event Swap(
        address indexed sender,
        address referenceTokenOut,
        uint256 amountOut,
        address referenceTokenIn,
        uint256 amountIn,
        address indexed to
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to,
        uint256 liquidity
    );

    event Mint(address indexed to, uint256 amount0, uint256 amount1);

    //FUNCTIONS
    modifier onlyValidToken(address _token) {
        if (_token != i_token0 && _token != i_token1) {
            revert Pair__InvalidToken();
        }
        _;
    }

    modifier deadlineNotPassed(uint256 _deadline) {
        if (block.timestamp > _deadline) {
            revert Pair__DeadlinePassed();
        }
        _;
    }

    constructor(address _token0, address _token1) {
        i_factory = msg.sender;
        i_token0 = _token0;
        i_token1 = _token1;
    }

    //EXTERNAL FUNCTIONS

    /// @dev Force reserves to match balances
    function sync() external nonReentrant {
        _update(
            IERC20(i_token0).balanceOf(address(this)),
            IERC20(i_token1).balanceOf(address(this)),
            s_reserve0,
            s_reserve1
        );
    }
    /// @dev force balances to match reserves
    /// @param _to Address to send the skimmed tokens to
    function skim(address _to) external nonReentrant {
        address token0 = i_token0; // gas savings
        address token1 = i_token1; // gas savings
        _safeTransfer(
            token0,
            _to,
            IERC20(token0).balanceOf(address(this)) - s_reserve0
        );
        _safeTransfer(
            token1,
            _to,
            IERC20(token1).balanceOf(address(this)) - s_reserve1
        );
    }

    /**
     * @dev Initiate a flash loan.
     * @param _receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param _token The loan currency.
     * @param _amount The amount of tokens lent.
     * @param _data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external nonReentrant onlyValidToken(_token) returns (bool) {
        if (_amount == 0) {
            revert Pair__InsufficientOutputAmount();
        }

        if (_amount > MAX_FLASH_LOAN) {
            revert Pair__MaxFlashLoanAmountExceeded();
        }

        uint256 fee = flashFee(_token, _amount);

        (uint112 reserve0, uint112 reserve1) = getReserves();

        uint256 referenceReserve = _token == i_token0 ? reserve0 : reserve1;

        if (_amount > referenceReserve) {
            revert Pair__InsufficientLiquidity();
        }

        _safeTransfer(_token, address(_receiver), _amount);

        bytes32 data = _receiver.onFlashLoan(
            msg.sender,
            _token,
            _amount,
            fee,
            _data
        );

        if (data != keccak256("ERC3156FlashBorrower.onFlashLoan")) {
            revert Pair__InvalidOnFlashLoanReturn();
        }
        //q apply k check here and make this swap more flexible
        bool success = IERC20(_token).transferFrom(
            address(_receiver),
            address(this),
            _amount + fee
        );

        if (!success) {
            revert Pair__TransferFailed();
        }

        uint256 balance0 = IERC20(i_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(i_token1).balanceOf(address(this));

        _update(balance0, balance1, reserve0, reserve1);

        return true;
    }

    /// @notice Deposit Pair tokens to mint liquidity tokens
    /// @dev Deposit Pair tokens to mint liquidity tokens. The fee is collected when a liquidity provider calls burn or mint.
    /// @param _amountA Amount of token0 to deposit
    /// @param _amountB Amount of token1 to deposit
    /// @param _mininimumLiquidity Minimum amount of liquidity tokens to mint
    /// @param _receiverAndDeadline address to send the tokens to and deadline for the transaction
    function mint(
        uint256 _amountA,
        uint256 _amountB,
        uint256 _mininimumLiquidity,
        ReceiverAndDeadline calldata _receiverAndDeadline
    )
        external
        nonReentrant
        deadlineNotPassed(_receiverAndDeadline.deadline)
        returns (uint256 liquidity)
    {
        bool successA = IERC20(i_token0).transferFrom(
            msg.sender,
            address(this),
            _amountA
        );

        bool successB = IERC20(i_token1).transferFrom(
            msg.sender,
            address(this),
            _amountB
        );

        if (!successA || !successB) {
            revert Pair__TransferFailed();
        }

        liquidity = _mintAndUpdate(
            _receiverAndDeadline.receiver,
            _mininimumLiquidity
        );
    }

    /// @notice Swap Pair tokens. For flashoans, use the dedicated flashLoan function
    /// @dev Swap tokens. This function does not support flash loans, which should be done using the dedicated flashLoan function
    /// @param _amountOut Amount of tokens to send to the user
    /// @param _tokenOut Token to send to the user
    /// @param _maximumAmountIn Maximum amount of tokens the user is willing to send to the contract
    /// @param _receiverAndDeadline address to send the tokens to and deadline for the transaction
    function swap(
        uint256 _amountOut,
        address _tokenOut,
        uint256 _maximumAmountIn,
        ReceiverAndDeadline calldata _receiverAndDeadline
    )
        external
        nonReentrant
        deadlineNotPassed(_receiverAndDeadline.deadline)
        onlyValidToken(_tokenOut)
    {
        if (_amountOut == 0) {
            revert Pair__InsufficientOutputAmount();
        }

        (uint112 reserve0, uint112 reserve1) = getReserves();

        SwapCache memory swapCache;

        if (_tokenOut == i_token0) {
            swapCache = SwapCache(_amountOut, 0, reserve1, reserve0, i_token1);
        } else {
            swapCache = SwapCache(0, _amountOut, reserve0, reserve1, i_token0);
        }

        if (_amountOut > swapCache.referenceReserveOut) {
            revert Pair__InsufficientLiquidity();
        }

        uint256 amountIn = _swapTokens(
            _tokenOut,
            swapCache.tokenIn,
            _receiverAndDeadline.receiver,
            _amountOut,
            _maximumAmountIn,
            swapCache.referenceReserveIn,
            swapCache.referenceReserveOut
        );

        _calculateAndValidateBalances(
            swapCache.amount0Out,
            swapCache.amount1Out,
            reserve0,
            reserve1
        );

        emit Swap(
            msg.sender,
            _tokenOut,
            _amountOut,
            swapCache.tokenIn,
            amountIn,
            _receiverAndDeadline.receiver
        );
    }

    /// @notice Burn liquidity tokens to get token0 and token1
    /// @dev Burn liquidity tokens to get token0 and token1
    /// @param _amount Amount of liquidity tokens to burn
    /// @param _amountAMin Minimum amount of token0 to receive
    /// @param _amountBMin Minimum amount of token1 to receive
    /// @param _receiverAndDeadline address to send the tokens to and deadline for the transaction
    function burn(
        uint256 _amount,
        uint256 _amountAMin,
        uint256 _amountBMin,
        ReceiverAndDeadline calldata _receiverAndDeadline
    ) external nonReentrant deadlineNotPassed(_receiverAndDeadline.deadline) {
        //q this transferFrom could be redundant since pair itself is the token
        bool success = IERC20(address(this)).transferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (!success) {
            revert Pair__TransferFailed();
        }

        _burnAndUpdate(
            _amount,
            _receiverAndDeadline.receiver,
            MinAmounts(_amountAMin, _amountBMin)
        );
    }

    //PUBLIC FUNCTIONS

    /// @dev Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return "Pair Token";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return "PT";
    }

    /// @notice Get reserves
    /// @dev Get reserves
    /// @return reserve0 Reserve of token0
    /// @return reserve1 Reserve of token1
    function getReserves()
        public
        view
        returns (uint112 reserve0, uint112 reserve1)
    {
        reserve0 = s_reserve0;
        reserve1 = s_reserve1;
    }

    ///@inheritdoc IERC3156FlashLender
    function maxFlashLoan(
        address _token
    ) public pure override returns (uint256) {
        return MAX_FLASH_LOAN;
    }

    ///@inheritdoc IERC3156FlashLender
    function flashFee(
        address _token,
        uint256 _amount
    ) public pure override returns (uint256) {
        return
            FixedPointMathLib.divUp(
                (_amount * FLASH_FEE),
                FLASH_FEE_DENOMINATOR
            );
    }

    //HELPER FUNCTIONS

    //INTERNAL FUNCTIONS
    /// @dev Update reserves and, on the first call per block, price accumulators
    /// @param _balance0 Balance of token0
    /// @param _balance1 Balance of token1
    /// @param _reserve0 Reserve of token0
    /// @param _reserve1 Reserve of token1
    function _update(
        uint256 _balance0,
        uint256 _balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) internal {
        unchecked {
            uint32 blockTimestamp = uint32(
                ((block.timestamp % (type(uint32).max)) + 1)
            );

            uint32 timeElapsed = blockTimestamp - s_blockTimestampLast; // overflow is desired

            if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
                s_price0CumulativeLast +=
                    uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                    timeElapsed;
                s_price1CumulativeLast +=
                    uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                    timeElapsed;
            }

            s_reserve0 = uint112(_balance0);
            s_reserve1 = uint112(_balance1);
            s_blockTimestampLast = blockTimestamp;

            emit Sync(s_reserve0, s_reserve1);
        }
    }

    /// @dev If fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    /// @param _reserve0 Reserve of token0
    /// @param _reserve1 Reserve of token1
    /// @return feeOn if fee is on, fees will be applied
    function _mintFee(
        uint256 _reserve0,
        uint256 _reserve1
    ) internal returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(i_factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = s_kLast;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = FixedPointMathLib.sqrt(
                    uint256(_reserve0) * uint256(_reserve1)
                );
                uint256 rootKLast = FixedPointMathLib.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply() * (rootK - rootKLast);
                    uint256 denominator = rootK * 5 + rootKLast;
                    uint256 liquidity = FixedPointMathLib.divUp(
                        numerator,
                        denominator
                    );
                    if (liquidity > 0) {
                        _mint(feeTo, liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            s_kLast = 0;
        }
    }

    /// @dev Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    /// @param _amountOut Amount of tokens to send to the user
    /// @param _reserveIn Reserve of the token to send to the user
    /// @param _reserveOut Reserve of the token to receive from the user
    /// @return amountIn Amount of tokens to send to the contract
    function _getAmountIn(
        uint256 _amountOut,
        uint256 _reserveIn,
        uint256 _reserveOut
    ) internal pure returns (uint256 amountIn) {
        if (_amountOut == 0) {
            revert Pair__InsufficientOutputAmount();
        }
        if (_reserveIn == 0 || _reserveOut == 0) {
            revert Pair__InsufficientLiquidity();
        }

        uint256 numerator = _reserveIn * _amountOut * FEE_DENOMINATOR;
        uint256 denominator = _reserveOut - _amountOut * FEE_FACTOR;

        amountIn = numerator / denominator + 1;
    }

    //PRIVATE FUNCTIONS
    /// @notice Safely transfer tokens
    /// @dev Reverts if the transfer fails or the balance of the contract decreases by more than the value transferred
    /// @param _token Token to be transferred
    /// @param _to Address to send tokens to
    /// @param _value Amount of tokens to be transferred
    function _safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) private {
        bytes4 functionSignature = bytes4(
            keccak256("transfer(address,uint256)")
        );
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        assembly {
            //Prepare arguments
            let freeMemoryLocation := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(freeMemoryLocation, functionSignature) // Place signature at beginning of empty storage
            mstore(add(freeMemoryLocation, 0x04), _to) // Place "to" argument next to signature
            mstore(add(freeMemoryLocation, 0x24), _value) // Place "value" argument next to "to"

            //call(gas, address, value, in, insize, out, outsize)
            let success := call(
                gas(),
                _token,
                0,
                freeMemoryLocation,
                0x44,
                freeMemoryLocation,
                0x20
            )
            // Only copy the first 32 bytes of the data to avoid memory expansion attack
            returndatacopy(freeMemoryLocation, 0, 0x20)

            // Check if the call was successful
            let data := mload(freeMemoryLocation)
            if iszero(success) {
                let errorMessage := "Pair__TransferFailed"
                let errorMessagePtr := add(freeMemoryLocation, 0x20) // Get the next free memory location
                mstore(errorMessagePtr, errorMessage) // Store the error message in memory
                revert(errorMessagePtr, 32) // Revert with the error message
            }
            let dataLength := returndatasize()
            if gt(dataLength, 0) {
                if iszero(mload(freeMemoryLocation)) {
                    let errorMessage := "Pair__TransferFailed"
                    let errorMessagePtr := add(freeMemoryLocation, 0x20) // Get the next free memory location
                    mstore(errorMessagePtr, errorMessage) // Store the error message in memory
                    revert(errorMessagePtr, 32) // Revert with the error message
                }
            }
        }

        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));

        unchecked {
            if (balanceBefore - balanceAfter > _value) {
                revert Pair__TransferFailed();
            }
        }
    }

    /// @dev Get the amount of the reference token that needs to be sent to the contract
    /// @param _referenceBalanceOut Balance of the reference token
    /// @param _referenceReserveOut Reserve of the reference token
    /// @param _amountOut Amount of tokens to send to the user
    /// @return referenceAmountIn Amount of tokens to send to the contract
    function _getReferenceAmountIn(
        uint256 _referenceBalanceOut,
        uint256 _referenceReserveOut,
        uint256 _amountOut
    ) private pure returns (uint256) {
        return
            _referenceBalanceOut > (_referenceReserveOut - _amountOut)
                ? _referenceBalanceOut - (_referenceReserveOut - _amountOut)
                : 0;
    }

    /// @dev Get the reference balance
    /// @param _token Token to be interacted with
    /// @param _balance0 Balance of token0
    /// @param _balance1 Balance of token1
    /// @return referenceBalance Balance of the reference token
    function _getReferenceBalance(
        address _token,
        uint256 _balance0,
        uint256 _balance1
    ) private view returns (uint256) {
        return _token == i_token0 ? _balance0 : _balance1;
    }

    /// @dev Calculate and validate balances
    /// @param _amount0Out Amount of tokens to send to the user
    /// @param _amount1Out Amount of tokens to send to the user
    /// @param _reserve0 Reserve of token0
    /// @param _reserve1 Reserve of token1
    function _calculateAndValidateBalances(
        uint256 _amount0Out,
        uint256 _amount1Out,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        uint256 balance0 = IERC20(i_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(i_token1).balanceOf(address(this));

        uint256 amount0In = _getReferenceAmountIn(
            balance0,
            _reserve0,
            _amount0Out
        );

        uint256 amount1In = _getReferenceAmountIn(
            balance1,
            _reserve1,
            _amount1Out
        );

        if (amount0In == 0 && amount1In == 0) {
            revert Pair__InsufficientInputAmount();
        }

        uint256 balance0Adjusted = balance0 * FEE_DENOMINATOR - amount0In * FEE;

        uint256 balance1Adjusted = balance1 * FEE_DENOMINATOR - amount1In * FEE;

        if (
            balance0Adjusted * balance1Adjusted <
            _reserve0 * _reserve1 * FEE_DENOMINATOR ** 2
        ) {
            revert Pair__NewBalanceCannotBeLessThanKLast();
        }

        _update(balance0, balance1, _reserve0, _reserve1);
    }

    /// @dev Swap tokens
    /// @param _tokenOut Token to send to the user
    /// @param _tokenIn Token to send to the contract
    /// @param _to Address to send tokens to
    /// @param _amountOut Amount of tokens to send to the user
    /// @param _maximumAmountIn Maximum amount of tokens the user is willing to send to the contract
    /// @param _reserveIn Reserve of tokenIn
    /// @param _reserveOut Reserve of tokenOut
    function _swapTokens(
        address _tokenOut,
        address _tokenIn,
        address _to,
        uint256 _amountOut,
        uint256 _maximumAmountIn,
        uint112 _reserveIn,
        uint112 _reserveOut
    ) private returns (uint256 amountIn) {
        amountIn = _getAmountIn(_amountOut, _reserveIn, _reserveOut);

        if (amountIn > _maximumAmountIn) {
            revert Pair__AmountInOverLimit();
        }

        _safeTransfer(_tokenOut, _to, _amountOut);

        bool success = IERC20(_tokenIn).transferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        if (!success) {
            revert Pair__TransferFailed();
        }
    }

    /// @dev Mint liquidity tokens
    /// @param _to Address to send liquidity tokens to
    /// @param _minimumLiquidity Minimum amount of liquidity tokens to mint
    /// @return liquidity Amount of liquidity tokens minted
    function _mintAndUpdate(
        address _to,
        uint256 _minimumLiquidity
    ) private returns (uint256 liquidity) {
        (uint112 reserve0, uint112 reserve1) = getReserves();
        bool feeOn = _mintFee(reserve0, reserve1);

        uint256 balance0 = IERC20(i_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(i_token1).balanceOf(address(this));

        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        uint256 totalSupply = totalSupply();

        if (totalSupply == 0) {
            liquidity =
                FixedPointMathLib.sqrt(amount0 * amount1) -
                MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = FixedPointMathLib.min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }

        if (liquidity == 0) {
            revert Pair__MintZeroAmount();
        }

        if (liquidity < _minimumLiquidity) {
            revert Pair__InsufficientLiquidity();
        }

        _mint(_to, liquidity);

        _update(balance0, balance1, reserve0, reserve1);
        if (feeOn) {
            s_kLast = uint256(reserve0) * uint256(reserve1);
        }

        emit Mint(_to, amount0, amount1);
    }

    /// @dev Burn liquidity tokens and transfer pair tokens to the user
    /// @param _amount Amount of liquidity tokens to burn
    /// @param _to Address to send tokens to
    /// @param _minimumAmounts Minimum amount of tokens to receive
    function _burnAndUpdate(
        uint256 _amount,
        address _to,
        MinAmounts memory _minimumAmounts
    ) private {
        (uint112 reserve0, uint112 reserve1) = getReserves();

        address token0 = i_token0;
        address token1 = i_token1;

        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(reserve0, reserve1);

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 totalSupply = totalSupply();

        uint256 amount0 = (liquidity * balance0) / totalSupply;
        uint256 amount1 = (liquidity * balance1) / totalSupply;

        if (amount0 == 0 && amount1 == 0) {
            revert Pair__BurnZeroAmount();
        }

        if (
            amount0 < _minimumAmounts.amount0 ||
            amount1 < _minimumAmounts.amount1
        ) {
            revert Pair__InsufficientOutputAmount();
        }

        _burn(address(this), _amount);
        _safeTransfer(token0, _to, amount0);
        _safeTransfer(token1, _to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        _update(balance0, balance1, reserve0, reserve1);

        if (feeOn) {
            s_kLast = uint256(reserve0) * uint256(s_reserve1);
        }

        emit Burn(_to, amount0, amount1, _to, liquidity);
    }
}
