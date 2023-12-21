## [H-1] Anything stored on-chain can be accessed by anyone, solidity access control (i.e. private, public etc) is only applicable for contracts.

### Description:
> **`PasswordStore::s_password`** is accessible to anyone which defeats the protocol ideal `This contract allows you to store a private password that others won't be able to see.`. Solidity keywords is only applicable on contracts. But you are storing **s_password** on-chain, so, anyone can see it.

### Impact: 
> **s_password** is no more safe or private.

### Proof of Concept:
> Here is how one can attack your system
### Recommended Mitigation: