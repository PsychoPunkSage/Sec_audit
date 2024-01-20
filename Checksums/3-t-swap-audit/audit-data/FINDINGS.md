## [H-1]  Incorrect fee calculation in `TSwapPool::getInputAmountBasedOnOutput` causes protocol to take too many tokens from users, resulting in lost fees

### Description:
> The `getInputAmountBasedOnOutput` function is intended to calculate the amount of tokens a user should deposit given an amount of tokens of output tokens. However, the function currently miscalculates the resulting amount. When calculating the fee, it scales the amount by 10_000 instead of 1_000

### Impact: 
> Protocol takes more fees than expected from users.

### Recommended Mitigation:
```diff
function getInputAmountBasedOnOutput(
        uint256 outputAmount,
        uint256 inputReserves,
        uint256 outputReserves
    )
        public
        pure
        revertIfZero(outputAmount)
        revertIfZero(outputReserves)
        returns (uint256 inputAmount)
    {
-        return ((inputReserves * outputAmount) * 10_000) / ((outputReserves - outputAmount) * 997);
+        return ((inputReserves * outputAmount) * 1_000) / ((outputReserves - outputAmount) * 997);
    }
```


## [M-1] `TSwapPool::deposit` is missing deadline check, can cause transaction to complete even after the deadline has been reached

### Description:
> The `Deposit` function accepts a **deadline** parameter, according to natspec it is `The deadline for the transaction to be completed by`. But unfortunatel it is never used inside `TSwapPool::deposit`

> As a consequesnce, operations that add liquidity to the Pool might get executed at unexpected times, in market conditions where deposit rate is unfavourable. 

### Impact: 
> Transaction could be sent even though the market conditon is unfavourable, even adding a deadline parameter.

### Proof of Concept:
> The `deadline` parameter is unused.

### Recommended Mitigation:

Consider making the following changes:
```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint,
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        external
+       revertIfDeadlinePassed(deadline)
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
```

## [L-1] `TSwapPool::LiquidityAdded` has paramaters out of order, events will emit wrong information

### Description:
> When `LiquidityAdded` event is emitted in `TSwapPool::_addLiquidityMintAndTransfer` function, it logs value in incorrect order.<br>
> The `poolTokensToDeposit` value should go in the 3rd parameter position whereas the `wethToDeposit` value should go to second parameter position.

### Impact: 
> Event emission is incorrect, this will lead to malfunction in **off-chain functions**.

### Recommended Mitigation:
```diff
-emit LiquidityAdded(msg.sender, poolTokensToDeposit, wethToDeposit);
+emit LiquidityAdded(msg.sender, wethToDeposit, poolTokensToDeposit);
```


## [I-1] `PoolFactory__PoolDoesNotExist` is not used anywhere, it should be removed.

### Description:
> Since **PoolFactory__PoolDoesNotExist** is not used anywhere, it should be removed as it may create confusion in future.

### Recommended Mitigation
```diff
- error PoolFactory__PoolDoesNotExist(address tokenAddress);
+ 
```



## [I-2] Lacking zero address checks

### Description:
> Zero address checks are important to avoid any unintentional erroneous addresses.

### Recommended Mitigation:
```diff
# src/PoolFactory.sol
constructor(address wethToken) {
+        if (wethToken == address(0)){
+            revert();
+        }
        i_wethToken = wethToken;
    }

# src/TSwapPool.sol
constructor(
        address poolToken,
        address wethToken,
        string memory liquidityTokenName,
        string memory liquidityTokenSymbol
    ) ERC20(liquidityTokenName, liquidityTokenSymbol) {
+        if (wethToken == address(0)){
+            revert();
+        }
+        if (poolToken == address(0)){
+            revert();
+        }
        i_wethToken = IERC20(wethToken);
        i_poolToken = IERC20(poolToken);
    }
```


## [I-3] `PoolFactory__createPool` should use `.symbol()` instead of `.name()`

### Description:
Contract intends to concat `symbol` not name of token.

### Recommended Mitigation:
```diff
string memory liquidityTokenName = string.concat(
            "T-Swap ",
-            IERC20(tokenAddress).name()
+            IERC20(tokenAddress).symbol()
        );
        string memory liquidityTokenSymbol = string.concat(
            "ts",
-            IERC20(tokenAddress).name()
+            IERC20(tokenAddress).symbol()
        );
```


## [I-4] If an event has more than parameters, 3 must be indexed

### Description:
It is a good practice to index some parameters of the event, tis will also help some external services to used those indexed parameters.

### Recommended Mitigation:
```diff
event Swap(
        address indexed swapper,
-        IERC20 tokenIn,
+        IERC20 indexed tokenIn,
        uint256 amountTokenIn,
-        IERC20 tokenOut,
+        IERC20 indexed tokenOut,
        uint256 amountTokenOut
    );
```


## [I-5] It is always a good practice to follow `CEI` (Check, Execute, Interact)

### Description:
> CEI convention should be followed to avoid any kind of misbehaviour in smart-contract.

### Recommended Mitigation:
```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint,
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline // @Done-Audit-H: not being used...
    )
        external
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
    {
        ......
        if (totalLiquidityTokenSupply() > 0) {
            ......
        } else {
            // This will be the "initial" funding of the protocol. We are starting from blank here!
            // We just have them send the tokens in, and we mint liquidity tokens based on the weth
+           liquidityTokensToMint = wethToDeposit;
            _addLiquidityMintAndTransfer(
                wethToDeposit,
                maximumPoolTokensToDeposit,
                wethToDeposit
            );
-           liquidityTokensToMint = wethToDeposit;
        }
    }
```


## [I-6] ## [I-4] Use of "Magic numbers" are discouraged, it can be confusing to see random numbers pop out

### Description:
> It is the best practice to avoid using magic numbers as it often confuses people, it is much more readable if the numbers are given names.

### Recommended Mitigation:
```diff
+uint256 public constant PRIZE_POOL_PERCENTAGE = 997;
+uint256 public constant POOL_PRECISSION = 1000;
```


## [G-1] `TSwapPool:deposit:poolTokenReserves` is never used, so it should be removed from the code.

### Description:
> Unused/unnecessary variables should be removed form the codebase

### Recommended Mitigation:
```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint,
        uint256 maximumPoolTokensToDeposit,
        uint64 deadline
    )
        external
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
    {
        if (wethToDeposit < MINIMUM_WETH_LIQUIDITY) {
            revert TSwapPool__WethDepositAmountTooLow(
                MINIMUM_WETH_LIQUIDITY,
                wethToDeposit
            );
        }
        if (totalLiquidityTokenSupply() > 0) {
            uint256 wethReserves = i_wethToken.balanceOf(address(this));

-           uint256 poolTokenReserves = i_poolToken.balanceOf(address(this));
```

## [S-#] TITLE (Root Cause + Impact)

### Description:

### Impact: 

### Proof of Concept:

### Recommended Mitigation: