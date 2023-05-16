## System Requirements
- Memory: 2 GB RAM
- CPU: Single Core
- Disk: 25 GB SSD

## Tmux Usage (No need if you will use service)
- Opening a new tmux screen: ```tmux```
- List tmux screen: ```tmux ls```
- Opening a previously opened tmux screen: ```tmux attach -t tmuxsayfaismi```
- Exiting the tmux page:``ctrl+b`` and then just press ``d`` press

## System Update
```
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y
```

## Installing Go
```
ver="1.20.3"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

- ``go version``  when you type ``go version go1.20.3 linux/amd64`` to the result of the investigation.

## Celestia Light Node Installation
```
cd $HOME 
rm -rf celestia-node 
git clone https://github.com/celestiaorg/celestia-node.git 
cd celestia-node/ 
git checkout tags/v0.9.5
make build 
make install 
make cel-key 
```

- ``celestia version`` we should get the following output..
```
Semantic version: tags/v0.9.5
```

## Init Process
- Entering the command will create a new wallet named my_celes_key. Remember to save the address and mnemonics of this wallet!
```
celestia light init --p2p.network blockspacerace
```
- When the above command is entered, it should give a result like the following.
```
2023-03-27T21:05:40.875Z        INFO    node    nodebuilder/init.go:29  Initializing Light Node Store over '/root/.celestia-light-blockspacerace-0'
2023-03-27T21:05:40.876Z        INFO    node    nodebuilder/init.go:61  Saved config    {"path": "/root/.celestia-light-blockspacerace-0/config.toml"}
2023-03-27T21:05:40.876Z        INFO    node    nodebuilder/init.go:63  Accessing keyring...
2023-03-27T21:05:40.881Z        WARN    node    nodebuilder/init.go:135 Detected plaintext keyring backend. For elevated security properties, consider using the `file` keyring backend.
2023-03-27T21:05:40.882Z        INFO    node    nodebuilder/init.go:150 NO KEY FOUND IN STORE, GENERATING NEW KEY...    {"path": "/root/.celestia-light-blockspacerace-0/keys"}
2023-03-27T21:05:40.901Z        INFO    node    nodebuilder/init.go:155 NEW KEY GENERATED...

NAME: my_celes_key
ADDRESS: celestia1mfpxjqkr5xfcpqy4kt94fwsrpc5cfh4tc2dz47
MNEMONIC (save this somewhere safe!!!): 
stable theory promote obtain clerk loud wish know doctor multiply one stairs c........................
```
NOTE: The core ip, rpc port, grpc port in the ExecStart command are taken from the endpoints provided in the Celestia documentation (https://docs.celestia.org/nodes/blockspace-race/#rpc-endpoints) and there are alternatives. If you want, you can change here and use different endpoints. 

## Start Standard
- Enter the following code while on the Tmux screen.
```
celestia light start --core.ip https://rpc-blockspacerace.pops.one --core.rpc.port 26657 --core.grpc.port 9090 --keyring.accname my_celes_key --metrics.tls=false --metrics --metrics.endpoint otel.celestia.tools:4318 --gateway --gateway.addr localhost --gateway.port 26659 --p2p.network blockspacerace
```

## Start with Service
```
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-lightd.service
[Unit]
Description=celestia-lightd Light Node
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/local/bin/celestia light start --core.ip https://rpc-blockspacerace.pops.one --core.rpc.port 26657 --core.grpc.port 9090 --keyring.accname my_celes_key --metrics.tls=false --metrics --metrics.endpoint otel.celestia.tools:4318 --gateway --gateway.addr localhost --gateway.port 26659 --p2p.network blockspacerace
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
```
```
systemctl enable celestia-lightd
systemctl start celestia-lightd
journalctl -u celestia-lightd.service -f
```
- Once synchronised to the system, the logs should look similar to the following.
```
INFO    header/store    store/store.go:349      new head        {"height": 106151, "hash": "CD084A85460978EC8C9E4BA23EE3847B28A90A879245E46F68B8133E413EA7A3"}
INFO    das     das/subscriber.go:34    new header received via subscription    {"height": 106151}
INFO    das     das/worker.go:79        finished sampling headers       {"from": 106151, "to": 106151, "errors": 0, "finished (s)": 0.000060704}
WARN    header/sync     sync/sync_head.go:140   received known network header   {"current_height": 106151, "header_height": 106151, "header_hash": "CD084A85460978EC8C9E4BA23EE3847B28A90A879245E46F68B8133E413EA7A3"}
INFO    header/store    store/store.go:349      new head        {"height": 106152, "hash": "C0FA44EF29FDE75ECD069A2031CC0A8BE94996F775FC106F76B88CCA514B1EF9"}
INFO    das     das/subscriber.go:34    new header received via subscription    {"height": 106152}
INFO    das     das/worker.go:79        finished sampling headers       {"from": 106152, "to": 106152, "errors": 0, "finished (s)": 0.00005358}
```
## Learning Node ID
```
AUTH_TOKEN=$(celestia light auth admin --p2p.network blockspacerace)
```
```
curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658
```
- When this code is entered, you will get a result like below ID="12D....." is your Node ID, you can find Uptime and other details by searching this on https://tiascan.com/light-nodes.
![11111](https://user-images.githubusercontent.com/73176377/228071707-5f6639e6-b51c-48a9-957a-33a317f5653b.PNG)

NOTE: ```/root/.celestia-light-blockspacerace-0``` under the keys folder must be backed up.

## Other Commands
Service Check
```
systemctl status celestia-lightd
```

Node Restart
```
systemctl restart celestia-lightd
```

Node Durdurma
```
systemctl stop celestia-lightd
```
