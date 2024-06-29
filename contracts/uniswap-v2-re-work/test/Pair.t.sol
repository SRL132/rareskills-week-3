// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {Pair} from "../src/Pair.sol";
import {TokenA} from "./mocks/TokenA.sol";
import {TokenB} from "./mocks/TokenB.sol";
import {UniswapV2Callee} from "./mocks/UniswapV2Callee.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

contract PairTest is StdInvariant, Test {
    Factory public factory;
    Pair public pair;
    TokenA public tokenA;
    TokenB public tokenB;
    UniswapV2Callee public uniswapV2Callee;
    address public feeToSetter = makeAddr("FEE_TO_SETTER");
    address newFeeToSetter = makeAddr("NEW_FEE_TO_SETTER");
    address tokenAAdress;
    address tokenBAdress;
    address user = makeAddr("USER");
    uint256 public constant MINTED_TOKEN_AMOUNT = 10_000;
    uint256 public constant MINIMUM_SWAP_AMOUNT = 1000;
    uint256 public constant FLASH_LOAN_AMOUNT = 1000;
    uint256 public constant BURN_AMOUNT = 1000;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    function setUp() public {
        vm.prank(feeToSetter);
        factory = new Factory(feeToSetter);
        tokenA = new TokenA();
        tokenB = new TokenB();
        tokenAAdress = address(tokenA);
        tokenBAdress = address(tokenB);
        pair = Pair(factory.createPair(tokenAAdress, tokenBAdress));
        uniswapV2Callee = new UniswapV2Callee(
            address(pair),
            tokenAAdress,
            tokenBAdress
        );
    }

    modifier hasMinted() {
        vm.startPrank(user);
        tokenA.mint(user, MINTED_TOKEN_AMOUNT);
        tokenB.mint(user, MINTED_TOKEN_AMOUNT);
        tokenA.approve(address(pair), MINTED_TOKEN_AMOUNT);
        tokenB.approve(address(pair), MINTED_TOKEN_AMOUNT);
        pair.mint(
            MINTED_TOKEN_AMOUNT,
            MINTED_TOKEN_AMOUNT,
            MINIMUM_LIQUIDITY,
            Pair.ReceiverAndDeadline(user, block.timestamp + 1000)
        );
        vm.stopPrank();
        _;
    }

    function testPairName() public view {
        assertEq(pair.name(), "Pair Token");
    }

    function testPairSymbol() public view {
        assertEq(pair.symbol(), "PT");
    }

    function testTokenAName() public view {
        assertEq(tokenA.name(), "Token A");
    }

    function testTokenASymbol() public view {
        assertEq(tokenA.symbol(), "TA");
    }

    function testTokenBName() public view {
        assertEq(tokenB.name(), "Token B");
    }

    function testTokenBSymbol() public view {
        assertEq(tokenB.symbol(), "TB");
    }

    function testPairInitialize() public view {
        assertEq(pair.i_token0(), tokenBAdress);
        assertEq(pair.i_token1(), tokenAAdress);
    }

    function testSwapRevertsIfInsufficientOutputAmount() public {
        vm.expectRevert();
        pair.swap(
            0,
            address(tokenA),
            MINIMUM_SWAP_AMOUNT,
            Pair.ReceiverAndDeadline(user, block.timestamp)
        );
    }

    function testSwapRevertsIfInsufficientLiquidity() public {
        vm.expectRevert();
        pair.swap(
            1,
            address(tokenB),
            MINIMUM_SWAP_AMOUNT,
            Pair.ReceiverAndDeadline(user, block.timestamp)
        );
    }

    function testFirstMint() public {
        vm.startPrank(user);
        tokenA.mint(user, MINTED_TOKEN_AMOUNT);
        tokenB.mint(user, MINTED_TOKEN_AMOUNT);
        tokenA.approve(address(pair), MINTED_TOKEN_AMOUNT);
        tokenB.approve(address(pair), MINTED_TOKEN_AMOUNT);
        pair.mint(
            MINTED_TOKEN_AMOUNT,
            MINTED_TOKEN_AMOUNT,
            MINIMUM_LIQUIDITY,
            Pair.ReceiverAndDeadline(user, block.timestamp)
        );
        vm.stopPrank();
        assertEq(pair.balanceOf(user), 9000);
    }

    function testMinWithTokenA() public hasMinted {
        vm.startPrank(user);
        tokenA.mint(user, MINTED_TOKEN_AMOUNT);
        tokenB.mint(user, MINTED_TOKEN_AMOUNT);
        tokenA.approve(address(pair), MINTED_TOKEN_AMOUNT);
        tokenB.approve(address(pair), MINTED_TOKEN_AMOUNT);
        vm.expectRevert();
        pair.mint(
            MINTED_TOKEN_AMOUNT,
            0,
            MINIMUM_LIQUIDITY,
            Pair.ReceiverAndDeadline(user, block.timestamp)
        );
        vm.stopPrank();
        assertEq(pair.balanceOf(user), 9000);
    }

    function testMinWithTokenB() public hasMinted {
        vm.startPrank(user);
        tokenA.mint(user, MINTED_TOKEN_AMOUNT);
        tokenB.mint(user, MINTED_TOKEN_AMOUNT);
        tokenA.approve(address(pair), MINTED_TOKEN_AMOUNT);
        tokenB.approve(address(pair), MINTED_TOKEN_AMOUNT);
        vm.expectRevert();
        pair.mint(
            0,
            MINTED_TOKEN_AMOUNT,
            MINIMUM_LIQUIDITY,
            Pair.ReceiverAndDeadline(user, block.timestamp)
        );
        vm.stopPrank();
        assertEq(pair.balanceOf(user), 9000);
    }

    function testSecondMint() public hasMinted {
        vm.startPrank(user);
        tokenA.mint(user, MINTED_TOKEN_AMOUNT);
        tokenB.mint(user, MINTED_TOKEN_AMOUNT);
        tokenA.approve(address(pair), MINTED_TOKEN_AMOUNT);
        tokenB.approve(address(pair), MINTED_TOKEN_AMOUNT);
        pair.mint(
            MINTED_TOKEN_AMOUNT,
            MINTED_TOKEN_AMOUNT,
            MINIMUM_LIQUIDITY,
            Pair.ReceiverAndDeadline(user, block.timestamp)
        );
        vm.stopPrank();
        assertEq(pair.balanceOf(user), 19_000);
    }

    function testBurnInitialSupply() public hasMinted {
        vm.startPrank(user);
        pair.approve(address(pair), BURN_AMOUNT);
        pair.burn(
            BURN_AMOUNT,
            1,
            1,
            Pair.ReceiverAndDeadline(user, block.timestamp + 1000)
        );
        vm.stopPrank();
        assertEq(pair.balanceOf(user), MINTED_TOKEN_AMOUNT - 2000);
        assertEq(tokenA.balanceOf(address(user)), BURN_AMOUNT);
        assertEq(tokenB.balanceOf(address(user)), BURN_AMOUNT);
        assert(pair.totalSupply() > 0);
    }

    function testBurn() public hasMinted {
        vm.startPrank(user);
        pair.approve(address(pair), BURN_AMOUNT);
        pair.burn(
            BURN_AMOUNT,
            1,
            1,
            Pair.ReceiverAndDeadline(user, block.timestamp + 1000)
        );
        vm.stopPrank();
        assertEq(pair.balanceOf(user), MINTED_TOKEN_AMOUNT - 2000);
        assertEq(tokenA.balanceOf(address(user)), BURN_AMOUNT);
        assertEq(tokenB.balanceOf(address(user)), BURN_AMOUNT);
    }

    function testCannotSwapWithoutDeposit() public hasMinted {
        vm.prank(user);
        vm.expectRevert();
        pair.swap(
            1000,
            address(tokenA),
            MINIMUM_SWAP_AMOUNT,
            Pair.ReceiverAndDeadline(user, block.timestamp)
        );
    }

    function testFlashloanA() public hasMinted {
        vm.startPrank(user);
        tokenA.mint(user, MINTED_TOKEN_AMOUNT);
        tokenB.mint(user, MINTED_TOKEN_AMOUNT);
        tokenA.transfer(address(uniswapV2Callee), MINTED_TOKEN_AMOUNT);
        tokenB.transfer(address(uniswapV2Callee), MINTED_TOKEN_AMOUNT);
        uint256 pairBalanceBefore = pair.balanceOf(user);
        uniswapV2Callee.triggerFlashLoanA(FLASH_LOAN_AMOUNT);
        vm.stopPrank();
        assertEq(pair.balanceOf(user), pairBalanceBefore);
        assertEq(
            tokenA.balanceOf(address(uniswapV2Callee)),
            MINTED_TOKEN_AMOUNT -
                pair.flashFee(address(tokenA), FLASH_LOAN_AMOUNT)
        );
        assertEq(
            tokenB.balanceOf(address(uniswapV2Callee)),
            MINTED_TOKEN_AMOUNT
        );
    }

    function testFlashloanB() public hasMinted {
        vm.startPrank(user);
        tokenA.mint(user, MINTED_TOKEN_AMOUNT);
        tokenB.mint(user, MINTED_TOKEN_AMOUNT);
        tokenA.transfer(address(uniswapV2Callee), MINTED_TOKEN_AMOUNT);
        tokenB.transfer(address(uniswapV2Callee), MINTED_TOKEN_AMOUNT);
        uint256 pairBalanceBefore = pair.balanceOf(user);
        uniswapV2Callee.triggerFlashLoanB(FLASH_LOAN_AMOUNT);
        vm.stopPrank();
        assertEq(pair.balanceOf(user), pairBalanceBefore);
        assertEq(
            tokenA.balanceOf(address(uniswapV2Callee)),
            MINTED_TOKEN_AMOUNT
        );
        assertEq(
            tokenB.balanceOf(address(uniswapV2Callee)),
            MINTED_TOKEN_AMOUNT -
                pair.flashFee(address(tokenB), FLASH_LOAN_AMOUNT)
        );
    }

    function testSync() public hasMinted {
        vm.startPrank(user);
        pair.sync();
        vm.stopPrank();
    }

    function testSkim() public hasMinted {
        vm.startPrank(user);
        pair.skim(user);
        vm.stopPrank();
    }
}
