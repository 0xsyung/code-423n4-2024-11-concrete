import argparse
import logging
import os
import subprocess
import json
from multiprocessing import Process, Queue
from collections import namedtuple


pjoin = os.path.join
parser = argparse.ArgumentParser(description="Money-Printer Deployment Script")
parser.add_argument("--network", type=str, help="Network to deploy to", required=True)
parser.add_argument("--fqn", type=str, help="Deploy path and script name", required=True)
parser.add_argument("--private-key", type=str, help="Private key to deploy with", required=True)
parser.add_argument("--no-verify", type=bool, help="Skip verification", default=False)
parser.add_argument("--vaultDeployment", type=bool, help="Is this a new vault deployment?", default=False)
parser.add_argument("--currencySymbol", type=str, help="Symbol of currency to deploy", required=False)
parser.add_argument("--vaultAddress", type=str, help="Vault Address for protections ", required=False, default="")

log = logging.getLogger()

class Bunch:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

class ChildProcess:
    def __init__(self, func, *args):
        self.errq = Queue()
        self.process = Process(target=self._func, args=(func,args))

    def _func(self, func, args):
        try:
            func(*args)
        except Exception as e:
            self.errq.put(e)

    def start(self):
        self.process.start()

    def join(self):
        self.process.join()

    def get_error(self):
        return self.errq.get() if not self.errq.empty() else None
    
def main():
    args = parser.parse_args()
    log.info(f"Deploying Earn to {args.network}")

    if args.vaultDeployment:
        log.info("Identified as vault deployment")
        if not args.currencySymbol:
            raise ValueError("Currency symbol is required for vault deployment")
        v_settings_dir = pjoin(os.path.abspath("."), "deploy-config")
        v_network_settings = pjoin(v_settings_dir,"vault/"+ args.network + "."+ args.currencySymbol + ".json")
        os.environ["CURRENCY"] = read_json(v_network_settings)["underlyingCurrency"]
    
    os.environ["DEPLOYMENT_CONTEXT"] = args.network
    os.environ["VAULT_ADDRESS"] = args.vaultAddress
    settings_dir = pjoin(os.path.abspath("."), "deploy-config")
    paths = Bunch(
        network_settings=pjoin(settings_dir, args.network + ".json"),
        fqn=args.fqn,
        private_key=args.private_key,
        no_verify=args.no_verify
    )

    log.info("Deploying Contracts")
    deploy_contracts(paths)

def deploy_contracts(paths):
    deploy_config = read_json(paths.network_settings)
    os.environ["CHAIN_ID"] = str(deploy_config["chainId"])
    os.environ["PRIVATE_KEY"] = paths.private_key

    run_command([
        'forge', 'script', paths.fqn, '--rpc-url', deploy_config["rpcUrl"], "--private-key", paths.private_key, '--broadcast',
        '--verify' if not paths.no_verify else '', '--verifier-url', deploy_config["verifierUrl"], '--etherscan-api-key', deploy_config["etherscanApiKey"],
        '--via-ir', "-vvvv","--skip-simulation"
    ],
    env={}, cwd=os.getcwd())

def read_json(path):
    with open(path, "r") as f:
        return json.load(f)
    
def run_command(args, check=True, shell=False, cwd=None, env=None, timeout=None, capture_output=False):
    env = env if env else {}
    return subprocess.run(
        args,
        capture_output=capture_output,
        check=check,
        shell=shell,
        env={
            **os.environ,
            **env
        },
        cwd=cwd,
        timeout=timeout
    )

