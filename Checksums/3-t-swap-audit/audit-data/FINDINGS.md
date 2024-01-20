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


## [S-#] TITLE (Root Cause + Impact)

### Description:

### Impact: 

### Proof of Concept:

### Recommended Mitigation: