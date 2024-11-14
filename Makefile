PYTHON?=python3

deploy-arb-vtn:
	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="arb-vtn" --fqn="script/DeployEarn.s.sol:DeployEarn" --private-key=$(private_key)
.PHONY: deploy-arb-vtn

deploy-vault:
	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="arb-vtn" --fqn="script/DeployNewVault.s.sol:DeployNewVault" --private-key=$(private_key) --vaultDeployment=true --currencySymbol=$(symbol)
.PHONY: deploy-vault

deploy-protect-strat:
	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="arb-vtn" --fqn="script/strategies/DeployProtectStratAndAssign.s.sol:DeployProtectStratAndAssign" --private-key=$(private_key) --vaultAddress=$(vault)
.PHONY: deploy-protect-strat

deploy-aave-strat:
	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="arb-vtn" --fqn="script/strategies/DeployAaveStratAndAssign.s.sol:DeployAaveStratAndAssign" --private-key=$(private_key) --vaultAddress=$(vault)
.PHONY: deploy-aave-strat

deploy-compound-strat:
	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="arb-vtn" --fqn="script/strategies/DeployCompoundStratAndAssign.s.sol:DeployCompoundStratAndAssign" --private-key=$(private_key) --vaultAddress=$(vault)
.PHONY: deploy-compound-strat

deploy-radiant-strat:
	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="arb-vtn" --fqn="script/strategies/DeployRadiantStratAndAssign.s.sol:DeployRadiantStratAndAssign" --private-key=$(private_key) --vaultAddress=$(vault)
.PHONY: deploy-radiant-strat

deploy-silo-strat:
	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="arb-vtn" --fqn="script/strategies/DeploySiloStratAndAssign.s.sol:DeploySiloStratAndAssign" --private-key=$(private_key) --vaultAddress=$(vault)
.PHONY: deploy-silo-strat

#Command(vault): make deploy-arb-vtn private_key="PRIVATE_KEY"
#Command(strategy): make deploy-xxx-strat private_key="PRIVATE_KEY" vault="VAULT_ADDR"
# deploy-new-arb-vtn:
# 	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="601574" --fqn="script/DeployEarn.s.sol:DeployEarn" --private-key=$(private_key)
# .PHONY: deploy-new-arb-vtn


# deploy-new-vault:
# 	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="601574" --fqn="script/DeployNewVault.s.sol:DeployNewVault" --private-key=$(private_key) --vaultDeployment=true --currencySymbol=$(symbol)
# .PHONY: deploy-new-vault

# deploy-new-protect-strat:
# 	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="601574" --fqn="script/strategies/DeployProtectStratAndAssign.s.sol:DeployProtectStratAndAssign" --private-key=$(private_key) --vaultAddress=$(vault)
# .PHONY: deploy-new-protect-strat

# deploy-new-aave-strat:
# 	PYTHONPATH=./protocol-deploy $(PYTHON) ./protocol-deploy/main.py --network="601574" --fqn="script/strategies/DeployAaveStratAndAssign.s.sol:DeployAaveStratAndAssign" --private-key=$(private_key) --vaultAddress=$(vault)
# .PHONY: deploy-new-aave-strat