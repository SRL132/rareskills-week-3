// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {Pair} from "../src/Pair.sol";
import {TokenA} from "./mocks/TokenA.sol";
import {TokenB} from "./mocks/TokenB.sol";

contract FactoryTest is Test {
    Factory public factory;
    Pair public pair;
    TokenA public tokenA;
    TokenB public tokenB;
    address public feeToSetter = makeAddr("FEE_TO_SETTER");
    address newFeeToSetter = makeAddr("NEW_FEE_TO_SETTER");

    function setUp() public {
        vm.prank(feeToSetter);
        factory = new Factory(feeToSetter);
        tokenA = new TokenA();
        tokenB = new TokenB();
        pair = new Pair(address(tokenA), address(tokenB));
    }

    function testFeeToSetter() public view {
        assertEq(factory.feeToSetter(), feeToSetter);
    }

    function testFeeTo() public view {
        assertEq(factory.feeTo(), address(0));
    }

    function testCanSetFeeTo() public {
        address feeTo = makeAddr("FEE_TO");
        vm.prank(feeToSetter);
        factory.setFeeTo(feeTo);
        assertEq(factory.feeTo(), feeTo);
    }

    function testOnlyFeeToSetterCanChangeSetFeeTo(address _notOwner) public {
        vm.assume(_notOwner != feeToSetter);
        address feeTo = makeAddr("FEE_TO");
        vm.prank(_notOwner);
        vm.expectRevert();
        factory.setFeeTo(feeTo);
    }

    function testCanSetFeeToSetter() public {
        vm.prank(feeToSetter);
        factory.setFeeToSetter(newFeeToSetter);
        assertEq(factory.feeToSetter(), newFeeToSetter);
    }

    function testOnlyFeeToSetterCanChangeSetFeeToSetter(
        address _notOwner
    ) public {
        vm.assume(_notOwner != feeToSetter);
        vm.prank(_notOwner);
        vm.expectRevert();
        factory.setFeeToSetter(newFeeToSetter);
    }

    function testallPairsCount() public view {
        assertEq(factory.allPairsCount(), 0);
    }

    function testCreatePair() public {
        factory.createPair(address(tokenA), address(tokenB));
        assertEq(factory.allPairsCount(), 1);
    }

    function testCreatePairWithIdenticalAddresses() public {
        vm.expectRevert();
        factory.createPair(address(tokenA), address(tokenA));
    }

    function testCreatePairWithZeroAddress() public {
        vm.expectRevert();
        factory.createPair(address(0), address(tokenA));
    }

    function testCreatePairWithPairAlreadyExists() public {
        factory.createPair(address(tokenA), address(tokenB));
        vm.expectRevert();
        factory.createPair(address(tokenA), address(tokenB));
        vm.expectRevert();
        factory.createPair(address(tokenB), address(tokenA));
    }

    function testGetPair() public {
        factory.createPair(address(tokenA), address(tokenB));
    }
}
