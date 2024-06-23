# Uniswap
## Overview
- RareSkills Uniswap V2 Book ([link](https://www.rareskills.io/uniswap-v2-book))

## Why does the price0CumulativeLast and price1CumulativeLast never decrement?
- Because the oracle accumulates the price for a given period of time to later use it as a reference to compute the weighted average, since we will have the total (priceAccumulated) so that we can divide it later by the time elapsed (how long that latest price lasted).

- In the event increasing to a point where overflows happen, due to the laws of arithmetics this is not an issue. Per Example:
We snapshot the priceAccumulator at 80 and a few transactions/blocks later the priceAccumulator goes to 110, but it overflows to 10. We subtract 80 from 10, which gives -70. But the value is stored as an unsigned integer, so it gives -70 mod(100) which is 30. That’s the same result we would expect if it didn’t overflow (110-80=30).



## How do you write a contract that uses the oracle?
  1. I write a contract with a cummulative price storage variable for the token's which price I want to track
  2. I write an update function that will update the price storage. I also add a timestamp uint variable to check when the latest price was updated
  3. In order to prevent sudden drastic price changes, I apply TWA Pricing to it by checking the time elapsed between the last price change and the time when the update price function is called. 
  4. I apply the update function when minting and burning these tokens if the price is a ratio between their supply
  5. I write a sync function to allow users to force an update for the case where there have been no price-changing interactions for longer than expected

## Why are price0CumulativeLast and price1CumulativeLast stored separately? Why not just calculate `price1CumulativeLast = 1/price0CumulativeLast?
- Because, while this would work with static prices, it does not work when accumulating prices. Per example, if the price accumulator starts at 2 and adds 3, we would notice the following:
  1 ETH = 2 USDC
  then
  1 ETH = 3 USDC

  (1/2 + 1/3) != 1/(2 + 3) 

Hence, it is necessary to accumulate them separately due to this dynamic nature