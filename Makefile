tests:
	forge test --fork-url https://rpc.ankr.com/eth --via-ir -vvv
approve:
	forge script script/Approve.s.sol:ApproveScript --fork-url https://rpc.ankr.com/eth --via-ir
test-deploy-goerli:
	forge script script/Deploy.s.sol:DeployScript --fork-url https://rpc.ankr.com/eth_goerli --via-ir
test-deploy-arbitrum:
	forge script script/Deploy.s.sol:DeployScript --fork-url https://arbitrum.llamarpc.com --via-ir