# Aori Vaults Template

This boilerplate is a simple ERC4626 vault template that can be used to interact with Aori.

```solidity
contract OrderVault is ERC4626 {
    
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public owner;
    address public orderProtocol;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _orderProtocol,
        IERC20 asset,
        string memory name,
        string memory symbol
    ) ERC4626(asset) ERC20(name, symbol) {
        owner = msg.sender;
        orderProtocol = _orderProtocol;
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function makeTrade(
        IOrderProtocol.MatchingDetails memory matching,
        IOrderProtocol.Signature memory serverSignature
    ) external {
        require(owner == msg.sender, "Only owner can call this function");
        IOrderProtocol(orderProtocol).settleOrders(matching, serverSignature);
    }

    function makeExternalCall(address to, uint256 value, bytes memory data) external returns (bool, bytes memory) {
        require(owner == msg.sender, "Only owner can call this function");
        (bool success, bytes memory returnedData) = (to).call{value: value}(data);
        return (success, returnedData);
    }

    /*//////////////////////////////////////////////////////////////
                                  MISC
    //////////////////////////////////////////////////////////////*/

    fallback () external {}
}
```

The owner of a vault can make and take limit orders for the vault off-chain, settling them with the vault's assets on-chain through the use of `makeTrade`.

External calls can also be made e.g `makeExternalCall`.