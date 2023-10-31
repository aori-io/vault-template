# Aori Vaults Template

![.](assets/aori-vault-template.svg)

This boilerplate is a simple multi-token vault template that can be used to interact with Aori.

```solidity
contract OrderVault is IERC1271 {

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 constant internal ERC1271_MAGICVALUE = 0x1626ba7e;
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public orderProtocol;

    mapping (address => bool) public managers;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _orderProtocol
    ) {
        owner = msg.sender;
        managers[owner] = true;
        orderProtocol = _orderProtocol;
    }

    /*//////////////////////////////////////////////////////////////
                                 CALLS
    //////////////////////////////////////////////////////////////*/

    function makeTrade(
        IOrderProtocol.MatchingDetails memory matching,
        IOrderProtocol.Signature memory serverSignature
    ) external {
        // ...
    }

    function makeExternalCall(address to, uint256 value, bytes memory data) external returns (bool, bytes memory) {
        // ...
    }

    /*//////////////////////////////////////////////////////////////
                                EIP-1271
    //////////////////////////////////////////////////////////////*/

    function isValidSignature(bytes32 _hash, bytes memory _signature) public view returns (bytes4) {
        // ...
    }

    /*//////////////////////////////////////////////////////////////
                               MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setManager(address _manager, bool _isManager) external {
        // ...
    }

    /*//////////////////////////////////////////////////////////////
                                  MISC
    //////////////////////////////////////////////////////////////*/

    receive () external payable {}
    fallback () external payable {}
}
```

Managers of the vault can make and take limit orders for the vault off-chain, settling them with the vault's assets on-chain through the use of `makeTrade`.

External calls can also be made via `makeExternalCall` e.g `ERC20` approvals.

To run the tests, run:
```
forge test --via-ir --fork-url $YOUR_RPC_URL

```


