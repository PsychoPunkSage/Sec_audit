## [H-1] Anything stored on-chain can be accessed by anyone, solidity access control (i.e. private, public etc) is only applicable for contracts.

### Description:
> **`PasswordStore::s_password`** is accessible to anyone which defeats the protocol ideal `This contract allows you to store a private password that others won't be able to see.`. Solidity keywords is only applicable on contracts. But you are storing **s_password** on-chain, so, anyone can see it.

### Impact: 
> **s_password** is no more safe or private.

### Proof of Concept:
> Here is how one can attack your system.

1. Run **anvil**:
```bash
anvil
```

2. Deploy the Contract
```bash
make deploy
```

3. Read the Storage slot of **s_password** (i.e. 1) using *cast*
```bash
cast storage <CONTRACT_ADDRESS> 1
```
Output (on success) : `0x6d7950617373776f726400000000000000000000000000000000000000000014`

4. Decode the data obtained from step:3
```bash
cast parse-bytes32-string 0x6d7950617373776f726400000000000000000000000000000000000000000014
```
Output (on success) : `myPassword`

### Recommended Mitigation:
>Due to this, the overall architecture of the contract should be rethought. One could encrypt the password off-chain, and then store the encrypted password on-chain. This would require the user to remember another password off-chain to decrypt the password. However, you'd also likely want to remove the view function as you wouldn't want the user to accidentally send a transaction with the password that decrypts your password.