## System Requirements
- Memory: 8 GB RAM
- CPU: Quad-Core
- Disk: 250 GB SSD Storage
- Bandwidth: 1 Gbps for Download/100 Mbps for Upload

## System Update
```
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y
```

## Installing Go
```
ver="1.20"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
```

- ``go version``  when you type ``go version go1.20 linux/amd64`` to the result of the investigation.

## Celestia Full Storage Node Installation
```
cd $HOME 
rm -rf celestia-node 
git clone https://github.com/celestiaorg/celestia-node.git 
cd celestia-node/ 
git checkout tags/v0.8.1 
make build 
make install 
make cel-key 
```

- ``celestia version`` we should get the following output..
```
Semantic version: v0.8.1 
Commit: 2718b1dfb7ee4fbcc8614601dc7d58019bfb1437 
Build Date: Thu Dec 15 10:19:22 PM UTC 2022 
System version: amd64/linux 
Golang version: go1.20
```

## Inıt Process
```
celestia full init --p2p.network blockspacerace
```

- Back up our wallet address and our words. 
- You can view your wallet with this code.
```
./cel-key list --node.type full --p2p.network blockspacerace
```

## Start with Service
```
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-fulld.service
[Unit]
Description=celestia-fulld Full Node
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/local/bin/celestia full start --core.ip https://rpc-blockspacerace.pops.one --core.rpc.port 26657 --core.grpc.port 9090 --keyring.accname my_celes_key --metrics.tls=false --metrics --metrics.endpoint otel.celestia.tools:4318 --gateway --gateway.addr localhost --gateway.port 26659 --p2p.network blockspacerace
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
```

NOTE: The core ip, rpc port, grpc port in the ExecStart command are taken from the endpoints provided in the Celestia documentation (https://docs.celestia.org/nodes/blockspace-race/#rpc-endpoints) and there are alternatives. If you want, you can change here and use different endpoints.

```
systemctl enable celestia-fulld
systemctl start celestia-fulld
```
- Log Control
```
journalctl -u celestia-fulld.service -f
```

## Learning Node ID
```
AUTH_TOKEN=$(celestia full auth admin --p2p.network blockspacerace)
```
```
curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658
```

- When this code is entered, you will get a result like below ID="12D....." is your Node ID, you can find Uptime and other details by searching this on https://tiascan.com/full-storage.

![bbbbb](https://user-images.githubusercontent.com/73176377/229496749-562366e9-6b79-4fa5-a266-1b6b3bdacb76.PNG)

- NOTE: You need to back up the keys folder under the .celestia-bridge-blockspacerace-0 folder with WinSCP or a tool with the same function.

