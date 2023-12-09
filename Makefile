tests:
	forge test --fork-url https://rpc.ankr.com/eth --fork-block-number 17867100 --via-ir -vvv
test-deploy-goerli:
	forge script script/Deploy.s.sol:DeployScript --fork-url https://rpc.ankr.com/eth_goerli --via-ir