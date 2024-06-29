## 1. Unused variables
Compiler run successful with warnings:
Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> src/Pair.sol:372:9:
    |
372 |         address _token
    |         ^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
   --> src/Pair.sol:379:9:
    |
379 |         address _token,
    |         ^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
  --> test/mocks/UniswapV2Callee.sol:48:9:
   |
48 |         address _initiator,
   |         ^^^^^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
  --> test/mocks/UniswapV2Callee.sol:49:9:
   |
49 |         address _token,
   |         ^^^^^^^^^^^^^^

Warning (5667): Unused function parameter. Remove or comment out the variable name to silence this warning.
  --> test/mocks/UniswapV2Callee.sol:52:9:
   |
52 |         bytes calldata _data
   |         ^^^^^^^^^^^^^^^^^^^^

## 2. Main Analysis
INFO:Detectors:
Pair.flashLoan(IERC3156FlashBorrower,address,uint256,bytes) (src/Pair.sol#158-212) uses arbitrary from in transferFrom: success = IERC20(_token).transferFrom(address(_receiver),address(this),_amount + fee) (src/Pair.sol#196-200)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#arbitrary-from-in-transferfrom
INFO:Detectors:
Pair._update(uint256,uint256,uint112,uint112) (src/Pair.sol#397-425) uses a weak PRNG: "blockTimestamp = uint32(((block.timestamp % (type()(uint32).max)) + 1)) (src/Pair.sol#404-406)" 
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#weak-PRNG
INFO:Detectors:
IERC20 is re-used:
        - IERC20 (lib/forge-std/src/interfaces/IERC20.sol#6-43)
        - IERC20 (src/interfaces/IERC20.sol#4-25)
IERC721TokenReceiver is re-used:
        - IERC721TokenReceiver (lib/forge-std/src/interfaces/IERC721.sol#105-121)
        - IERC721TokenReceiver (lib/forge-std/src/mocks/MockERC721.sol#233-235)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#name-reused
INFO:Detectors:
stdStorageSafe.getMaskByOffsets(uint256,uint256) (lib/forge-std/src/StdStorage.sol#316-322) contains an incorrect shift operation: mask = 1 << 256 - offsetRight + offsetLeft - 1 << offsetRight (lib/forge-std/src/StdStorage.sol#320)
FixedPointMathLib.sMulWad(int256,int256) (lib/solady/src/utils/FixedPointMathLib.sol#77-88) contains an incorrect shift operation: ! ! x | z /' x == y > ~ x < y == 1 << 255 (lib/solady/src/utils/FixedPointMathLib.sol#82-85)
FixedPointMathLib.expWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#200-265) contains an incorrect shift operation: p = p * x + (4385272521454847904659076985693276 << 96) (lib/solady/src/utils/FixedPointMathLib.sol#235)
FixedPointMathLib.lnWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#269-339) contains an incorrect shift operation: r = r ^ byte(uint256,uint256)(0x1f & 0x8421084210842108cc6318c6db6d54be >> x >> r,0xf8f9f9faf9fdfafbf9fdfcfdfafbfcfef9fafdfafcfcfbfefafafcfbffffffff) (lib/solady/src/utils/FixedPointMathLib.sol#289-290)
FixedPointMathLib.lnWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#269-339) contains an incorrect shift operation: p_lnWad_asm_0 = p_lnWad_asm_0 * x - 795164235651350426258249787498 << 96 (lib/solady/src/utils/FixedPointMathLib.sol#306)
FixedPointMathLib.lambertW0Wad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#344-427) contains an incorrect shift operation: l_lambertW0Wad_asm_0 = l_lambertW0Wad_asm_0 | byte(uint256,uint256)(0x1f & 0x8421084210842108cc6318c6db6d54be >> v_lambertW0Wad_asm_0 >> l_lambertW0Wad_asm_0,0x0706060506020504060203020504030106050205030304010505030400000000) + 49 (lib/solady/src/utils/FixedPointMathLib.sol#364-365)
FixedPointMathLib.lambertW0Wad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#344-427) contains an incorrect shift operation: w = 7 << l_lambertW0Wad_asm_0 /' byte(uint256,uint256)(l_lambertW0Wad_asm_0 - 31,0x0303030303030303040506080c13) (lib/solady/src/utils/FixedPointMathLib.sol#366)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) contains an incorrect shift operation: z = 0xf << 0xf < x >> r_cbrt_asm_0 << r_cbrt_asm_0 / 3 / 7 ^ r_cbrt_asm_0 % 3 (lib/solady/src/utils/FixedPointMathLib.sol#680)
FixedPointMathLib.log2(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#738-750) contains an incorrect shift operation: r = r | byte(uint256,uint256)(0x1f & 0x8421084210842108cc6318c6db6d54be >> x >> r,0x0706060506020504060203020504030106050205030304010505030400000000) (lib/solady/src/utils/FixedPointMathLib.sol#747-748)
FixedPointMathLib.log2Up(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#754-760) contains an incorrect shift operation: r = r + 1 << r < x (lib/solady/src/utils/FixedPointMathLib.sol#758)
FixedPointMathLib.log256Up(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#812-818) contains an incorrect shift operation: r = r + 1 << r << 3 < x (lib/solady/src/utils/FixedPointMathLib.sol#816)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-shift-in-assembly
INFO:Detectors:
StdCheats.vm (lib/forge-std/src/StdCheats.sol#643) shadows:
        - StdCheatsSafe.vm (lib/forge-std/src/StdCheats.sol#11)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#state-variable-shadowing
INFO:Detectors:
PairTest.testFlashloanA() (test/Pair.t.sol#217-236) ignores return value by tokenA.transfer(address(uniswapV2Callee),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#221)
PairTest.testFlashloanA() (test/Pair.t.sol#217-236) ignores return value by tokenB.transfer(address(uniswapV2Callee),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#222)
PairTest.testFlashloanB() (test/Pair.t.sol#238-257) ignores return value by tokenA.transfer(address(uniswapV2Callee),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#242)
PairTest.testFlashloanB() (test/Pair.t.sol#238-257) ignores return value by tokenB.transfer(address(uniswapV2Callee),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#243)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unchecked-transfer
INFO:Detectors:
FixedPointMathLib.expWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#200-265) performs a multiplication on the result of a division:
        - x = (x << 78) / 5 ** 18 (lib/solady/src/utils/FixedPointMathLib.sol#219)
        - y = ((y * x) >> 96) + 57155421227552351082224309758442 (lib/solady/src/utils/FixedPointMathLib.sol#232)
FixedPointMathLib.expWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#200-265) performs a multiplication on the result of a division:
        - x = (x << 78) / 5 ** 18 (lib/solady/src/utils/FixedPointMathLib.sol#219)
        - p = p * x + (4385272521454847904659076985693276 << 96) (lib/solady/src/utils/FixedPointMathLib.sol#235)
FixedPointMathLib.expWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#200-265) performs a multiplication on the result of a division:
        - x = (x << 78) / 5 ** 18 (lib/solady/src/utils/FixedPointMathLib.sol#219)
        - q = ((q * x) >> 96) + 50020603652535783019961831881945 (lib/solady/src/utils/FixedPointMathLib.sol#239)
FixedPointMathLib.expWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#200-265) performs a multiplication on the result of a division:
        - x = (x << 78) / 5 ** 18 (lib/solady/src/utils/FixedPointMathLib.sol#219)
        - q = ((q * x) >> 96) - 533845033583426703283633433725380 (lib/solady/src/utils/FixedPointMathLib.sol#240)
FixedPointMathLib.expWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#200-265) performs a multiplication on the result of a division:
        - x = (x << 78) / 5 ** 18 (lib/solady/src/utils/FixedPointMathLib.sol#219)
        - q = ((q * x) >> 96) + 3604857256930695427073651918091429 (lib/solady/src/utils/FixedPointMathLib.sol#241)
FixedPointMathLib.expWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#200-265) performs a multiplication on the result of a division:
        - x = (x << 78) / 5 ** 18 (lib/solady/src/utils/FixedPointMathLib.sol#219)
        - q = ((q * x) >> 96) - 14423608567350463180887372962807573 (lib/solady/src/utils/FixedPointMathLib.sol#242)
FixedPointMathLib.expWad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#200-265) performs a multiplication on the result of a division:
        - x = (x << 78) / 5 ** 18 (lib/solady/src/utils/FixedPointMathLib.sol#219)
        - q = ((q * x) >> 96) + 26449188498355588339934803723976023 (lib/solady/src/utils/FixedPointMathLib.sol#243)
FixedPointMathLib.lambertW0Wad(int256) (lib/solady/src/utils/FixedPointMathLib.sol#344-427) performs a multiplication on the result of a division:
        - t_lambertW0Wad_asm_2 = w * e / wad (lib/solady/src/utils/FixedPointMathLib.sol#384)
FixedPointMathLib.fullMulDiv(uint256,uint256,uint256) (lib/solady/src/utils/FixedPointMathLib.sol#436-507) performs a multiplication on the result of a division:
        - d = d / t_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#477)
        - inv_fullMulDiv_asm_0 = 2 ^ 3 * d (lib/solady/src/utils/FixedPointMathLib.sol#483)
FixedPointMathLib.fullMulDiv(uint256,uint256,uint256) (lib/solady/src/utils/FixedPointMathLib.sol#436-507) performs a multiplication on the result of a division:
        - d = d / t_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#477)
        - inv_fullMulDiv_asm_0 = inv_fullMulDiv_asm_0 * 2 - d * inv_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#487)
FixedPointMathLib.fullMulDiv(uint256,uint256,uint256) (lib/solady/src/utils/FixedPointMathLib.sol#436-507) performs a multiplication on the result of a division:
        - d = d / t_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#477)
        - inv_fullMulDiv_asm_0 = inv_fullMulDiv_asm_0 * 2 - d * inv_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#488)
FixedPointMathLib.fullMulDiv(uint256,uint256,uint256) (lib/solady/src/utils/FixedPointMathLib.sol#436-507) performs a multiplication on the result of a division:
        - d = d / t_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#477)
        - inv_fullMulDiv_asm_0 = inv_fullMulDiv_asm_0 * 2 - d * inv_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#489)
FixedPointMathLib.fullMulDiv(uint256,uint256,uint256) (lib/solady/src/utils/FixedPointMathLib.sol#436-507) performs a multiplication on the result of a division:
        - d = d / t_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#477)
        - inv_fullMulDiv_asm_0 = inv_fullMulDiv_asm_0 * 2 - d * inv_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#490)
FixedPointMathLib.fullMulDiv(uint256,uint256,uint256) (lib/solady/src/utils/FixedPointMathLib.sol#436-507) performs a multiplication on the result of a division:
        - d = d / t_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#477)
        - inv_fullMulDiv_asm_0 = inv_fullMulDiv_asm_0 * 2 - d * inv_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#491)
FixedPointMathLib.fullMulDiv(uint256,uint256,uint256) (lib/solady/src/utils/FixedPointMathLib.sol#436-507) performs a multiplication on the result of a division:
        - d = d / t_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#477)
        - result = p1_fullMulDiv_asm_0 - r_fullMulDiv_asm_0 > result * 0 - t_fullMulDiv_asm_0 / t_fullMulDiv_asm_0 + 1 | result - r_fullMulDiv_asm_0 / t_fullMulDiv_asm_0 * inv_fullMulDiv_asm_0 * 2 - d * inv_fullMulDiv_asm_0 (lib/solady/src/utils/FixedPointMathLib.sol#492-503)
FixedPointMathLib.rpow(uint256,uint256,uint256) (lib/solady/src/utils/FixedPointMathLib.sol#578-612) performs a multiplication on the result of a division:
        - x = xxRound_rpow_asm_0 / b (lib/solady/src/utils/FixedPointMathLib.sol#594)
        - zx_rpow_asm_0 = z * x (lib/solady/src/utils/FixedPointMathLib.sol#597)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) performs a multiplication on the result of a division:
        - z = 0xf << 0xf < x >> r_cbrt_asm_0 << r_cbrt_asm_0 / 3 / 7 ^ r_cbrt_asm_0 % 3 (lib/solady/src/utils/FixedPointMathLib.sol#680)
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#682)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) performs a multiplication on the result of a division:
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#682)
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#683)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) performs a multiplication on the result of a division:
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#683)
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#684)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) performs a multiplication on the result of a division:
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#684)
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#685)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) performs a multiplication on the result of a division:
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#685)
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#686)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) performs a multiplication on the result of a division:
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#686)
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#687)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) performs a multiplication on the result of a division:
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#687)
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#688)
FixedPointMathLib.cbrt(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#671-692) performs a multiplication on the result of a division:
        - z = x / z * z + z + z / 3 (lib/solady/src/utils/FixedPointMathLib.sol#688)
        - z = z - x / z * z < z (lib/solady/src/utils/FixedPointMathLib.sol#690)
FixedPointMathLib.cbrtWad(uint256) (lib/solady/src/utils/FixedPointMathLib.sol#707-721) performs a multiplication on the result of a division:
        - x <= (type()(uint256).max / 10 ** 36) * 10 ** 18 - 1 (lib/solady/src/utils/FixedPointMathLib.sol#710)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
INFO:Detectors:
Pair._burnAndUpdate(uint256,address,Pair.MinAmounts) (src/Pair.sol#709-756) uses a dangerous strict equality:
        - amount0 == 0 && amount1 == 0 (src/Pair.sol#731)
Pair._calculateAndValidateBalances(uint256,uint256,uint112,uint112) (src/Pair.sol#581-618) uses a dangerous strict equality:
        - amount0In == 0 && amount1In == 0 (src/Pair.sol#602)
Pair._mintAndUpdate(address,uint256) (src/Pair.sol#660-703) uses a dangerous strict equality:
        - liquidity == 0 (src/Pair.sol#687)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dangerous-strict-equalities
INFO:Detectors:
Contract locking ether found:
        Contract MockERC721 (lib/forge-std/src/mocks/MockERC721.sol#8-231) has payable functions:
         - IERC721.safeTransferFrom(address,address,uint256,bytes) (lib/forge-std/src/interfaces/IERC721.sol#53)
         - IERC721.safeTransferFrom(address,address,uint256) (lib/forge-std/src/interfaces/IERC721.sol#61)
         - IERC721.transferFrom(address,address,uint256) (lib/forge-std/src/interfaces/IERC721.sol#73)
         - IERC721.approve(address,uint256) (lib/forge-std/src/interfaces/IERC721.sol#81)
         - MockERC721.approve(address,uint256) (lib/forge-std/src/mocks/MockERC721.sol#83-91)
         - MockERC721.transferFrom(address,address,uint256) (lib/forge-std/src/mocks/MockERC721.sol#99-120)
         - MockERC721.safeTransferFrom(address,address,uint256) (lib/forge-std/src/mocks/MockERC721.sol#122-131)
         - MockERC721.safeTransferFrom(address,address,uint256,bytes) (lib/forge-std/src/mocks/MockERC721.sol#133-147)
        But does not have a function to withdraw the ether
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#contracts-that-lock-ether
INFO:Detectors:
Reentrancy in Pair.flashLoan(IERC3156FlashBorrower,address,uint256,bytes) (src/Pair.sol#158-212):
        External calls:
        - data = _receiver.onFlashLoan(msg.sender,_token,_amount,fee,_data) (src/Pair.sol#184-190)
        - success = IERC20(_token).transferFrom(address(_receiver),address(this),_amount + fee) (src/Pair.sol#196-200)
        State variables written after the call(s):
        - _update(balance0,balance1,reserve0,reserve1) (src/Pair.sol#209)
                - s_reserve0 = uint112(_balance0) (src/Pair.sol#419)
        Pair.s_reserve0 (src/Pair.sol#42) can be used in cross function reentrancies:
        - Pair.getReserves() (src/Pair.sol#361-368)
        - _update(balance0,balance1,reserve0,reserve1) (src/Pair.sol#209)
                - s_reserve1 = uint112(_balance1) (src/Pair.sol#420)
        Pair.s_reserve1 (src/Pair.sol#43) can be used in cross function reentrancies:
        - Pair.getReserves() (src/Pair.sol#361-368)
Reentrancy in Pair.swap(uint256,address,uint256,Pair.ReceiverAndDeadline) (src/Pair.sol#259-313):
        External calls:
        - amountIn = _swapTokens(_tokenOut,swapCache.tokenIn,_receiverAndDeadline.receiver,_amountOut,_maximumAmountIn,swapCache.referenceReserveIn,swapCache.referenceReserveOut) (src/Pair.sol#288-296)
                - success = IERC20(_tokenIn).transferFrom(msg.sender,address(this),amountIn) (src/Pair.sol#645-649)
        State variables written after the call(s):
        - _calculateAndValidateBalances(swapCache.amount0Out,swapCache.amount1Out,reserve0,reserve1) (src/Pair.sol#298-303)
                - s_reserve0 = uint112(_balance0) (src/Pair.sol#419)
        Pair.s_reserve0 (src/Pair.sol#42) can be used in cross function reentrancies:
        - Pair.getReserves() (src/Pair.sol#361-368)
        - _calculateAndValidateBalances(swapCache.amount0Out,swapCache.amount1Out,reserve0,reserve1) (src/Pair.sol#298-303)
                - s_reserve1 = uint112(_balance1) (src/Pair.sol#420)
        Pair.s_reserve1 (src/Pair.sol#43) can be used in cross function reentrancies:
        - Pair.getReserves() (src/Pair.sol#361-368)


## 3. Tests
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
INFO:Detectors:
StdCheatsSafe.readEIP1559ScriptArtifact(string).artifact (lib/forge-std/src/StdCheats.sol#361) is a local variable never initialized
StdCheatsSafe.rawToConvertedEIP1559Detail(StdCheatsSafe.RawTx1559Detail).txDetail (lib/forge-std/src/StdCheats.sol#397) is a local variable never initialized
StdCheatsSafe.rawToConvertedReceiptLogs(StdCheatsSafe.RawReceiptLog[]).i (lib/forge-std/src/StdCheats.sol#473) is a local variable never initialized
StdCheatsSafe.rawToConvertedEIPTx1559(StdCheatsSafe.RawTx1559).transaction (lib/forge-std/src/StdCheats.sol#381) is a local variable never initialized
StdCheatsSafe.rawToConvertedReceipts(StdCheatsSafe.RawReceipt[]).i (lib/forge-std/src/StdCheats.sol#442) is a local variable never initialized
StdCheatsSafe.rawToConvertedEIPTx1559s(StdCheatsSafe.RawTx1559[]).i (lib/forge-std/src/StdCheats.sol#374) is a local variable never initialized
StdCheatsSafe.rawToConvertedReceipt(StdCheatsSafe.RawReceipt).receipt (lib/forge-std/src/StdCheats.sol#449) is a local variable never initialized
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#uninitialized-local-variables
INFO:Detectors:
StdChains.getChainWithUpdatedRpcUrl(string,StdChains.Chain) (lib/forge-std/src/StdChains.sol#151-186) ignores return value by vm.rpcUrl(chainAlias) (lib/forge-std/src/StdChains.sol#157-183)
StdCheatsSafe.isFork() (lib/forge-std/src/StdCheats.sol#576-580) ignores return value by vm.activeFork() (lib/forge-std/src/StdCheats.sol#577-579)
FactoryTest.testCreatePair() (test/Factory.t.sol#68-71) ignores return value by factory.createPair(address(tokenA),address(tokenB)) (test/Factory.t.sol#69)
FactoryTest.testCreatePairWithIdenticalAddresses() (test/Factory.t.sol#73-76) ignores return value by factory.createPair(address(tokenA),address(tokenA)) (test/Factory.t.sol#75)
FactoryTest.testCreatePairWithZeroAddress() (test/Factory.t.sol#78-81) ignores return value by factory.createPair(address(0),address(tokenA)) (test/Factory.t.sol#80)
FactoryTest.testCreatePairWithPairAlreadyExists() (test/Factory.t.sol#83-89) ignores return value by factory.createPair(address(tokenA),address(tokenB)) (test/Factory.t.sol#84)
FactoryTest.testCreatePairWithPairAlreadyExists() (test/Factory.t.sol#83-89) ignores return value by factory.createPair(address(tokenA),address(tokenB)) (test/Factory.t.sol#86)
FactoryTest.testCreatePairWithPairAlreadyExists() (test/Factory.t.sol#83-89) ignores return value by factory.createPair(address(tokenB),address(tokenA)) (test/Factory.t.sol#88)
FactoryTest.testGetPair() (test/Factory.t.sol#91-93) ignores return value by factory.createPair(address(tokenA),address(tokenB)) (test/Factory.t.sol#92)
PairTest.testFirstMint() (test/Pair.t.sol#109-123) ignores return value by tokenA.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#113)
PairTest.testFirstMint() (test/Pair.t.sol#109-123) ignores return value by tokenB.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#114)
PairTest.testFirstMint() (test/Pair.t.sol#109-123) ignores return value by pair.mint(MINTED_TOKEN_AMOUNT,MINTED_TOKEN_AMOUNT,MINIMUM_LIQUIDITY,Pair.ReceiverAndDeadline(user,block.timestamp)) (test/Pair.t.sol#115-120)
PairTest.testMinWithTokenA() (test/Pair.t.sol#125-140) ignores return value by tokenA.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#129)
PairTest.testMinWithTokenA() (test/Pair.t.sol#125-140) ignores return value by tokenB.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#130)
PairTest.testMinWithTokenA() (test/Pair.t.sol#125-140) ignores return value by pair.mint(MINTED_TOKEN_AMOUNT,0,MINIMUM_LIQUIDITY,Pair.ReceiverAndDeadline(user,block.timestamp)) (test/Pair.t.sol#132-137)
PairTest.testMinWithTokenB() (test/Pair.t.sol#142-157) ignores return value by tokenA.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#146)
PairTest.testMinWithTokenB() (test/Pair.t.sol#142-157) ignores return value by tokenB.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#147)
PairTest.testMinWithTokenB() (test/Pair.t.sol#142-157) ignores return value by pair.mint(0,MINTED_TOKEN_AMOUNT,MINIMUM_LIQUIDITY,Pair.ReceiverAndDeadline(user,block.timestamp)) (test/Pair.t.sol#149-154)
PairTest.testSecondMint() (test/Pair.t.sol#159-173) ignores return value by tokenA.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#163)
PairTest.testSecondMint() (test/Pair.t.sol#159-173) ignores return value by tokenB.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#164)
PairTest.testSecondMint() (test/Pair.t.sol#159-173) ignores return value by pair.mint(MINTED_TOKEN_AMOUNT,MINTED_TOKEN_AMOUNT,MINIMUM_LIQUIDITY,Pair.ReceiverAndDeadline(user,block.timestamp)) (test/Pair.t.sol#165-170)
PairTest.testBurnInitialSupply() (test/Pair.t.sol#175-189) ignores return value by pair.approve(address(pair),BURN_AMOUNT) (test/Pair.t.sol#177)
PairTest.testBurn() (test/Pair.t.sol#191-204) ignores return value by pair.approve(address(pair),BURN_AMOUNT) (test/Pair.t.sol#193)
PairTest.hasMinted() (test/Pair.t.sol#44-58) ignores return value by tokenA.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#48)
PairTest.hasMinted() (test/Pair.t.sol#44-58) ignores return value by tokenB.approve(address(pair),MINTED_TOKEN_AMOUNT) (test/Pair.t.sol#49)
PairTest.hasMinted() (test/Pair.t.sol#44-58) ignores return value by pair.mint(MINTED_TOKEN_AMOUNT,MINTED_TOKEN_AMOUNT,MINIMUM_LIQUIDITY,Pair.ReceiverAndDeadline(user,block.timestamp + 1000)) (test/Pair.t.sol#50-55)
UniswapV2Callee.triggerFlashLoanA(uint256) (test/mocks/UniswapV2Callee.sol#20-27) ignores return value by IERC3156FlashLender(i_uniswapPair).flashLoan(IERC3156FlashBorrower(address(this)),i_tokenA,_amount,) (test/mocks/UniswapV2Callee.sol#21-26)
UniswapV2Callee.triggerFlashLoanB(uint256) (test/mocks/UniswapV2Callee.sol#29-36) ignores return value by IERC3156FlashLender(i_uniswapPair).flashLoan(IERC3156FlashBorrower(address(this)),i_tokenB,_amount,) (test/mocks/UniswapV2Callee.sol#30-35)
UniswapV2Callee.onFlashLoan(address,address,uint256,uint256,bytes) (test/mocks/UniswapV2Callee.sol#47-57) ignores return value by IERC20(i_tokenA).approve(i_uniswapPair,_amount + _fee) (test/mocks/UniswapV2Callee.sol#54)
UniswapV2Callee.onFlashLoan(address,address,uint256,uint256,bytes) (test/mocks/UniswapV2Callee.sol#47-57) ignores return value by IERC20(i_tokenB).approve(i_uniswapPair,_amount + _fee) (test/mocks/UniswapV2Callee.sol#55)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#unused-return
