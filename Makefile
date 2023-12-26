tests:
	forge test --fork-url https://rpc.ankr.com/eth --via-ir -vvv
approve-router:
	forge script script/ApproveRouter.s.sol:ApproveRouterScript --fork-url https://arbitrum.llamarpc.com --via-ir --legacy
test-deploy-goerli:
	forge script script/Deploy.s.sol:DeployScript --fork-url https://rpc.ankr.com/eth_goerli --via-ir --broadcast
test-deploy-arbitrum:
	forge script script/Deploy.s.sol:DeployScript --fork-url https://arbitrum.llamarpc.com --via-ir --legacy --broadcast