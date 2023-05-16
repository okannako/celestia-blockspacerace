## System Requirements
- Memory: 8 GB RAM
- CPU: 6 Cores
- Disk: 500 GB SSD Storage
- Bandwidth: 1 Gbps for Download/100 Mbps for Upload

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

## Celestia-App Installation
```
cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v0.13.0 
git checkout tags/$APP_VERSION -b $APP_VERSION
make install
```

- Write ```celestia-appd version``` >>> 0.13.0

## P2P network
```
cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git
```

## Init Process
```
celestia-appd init "node-name" --chain-id blockspacerace-0
```
## Move Genesis
```
cp $HOME/networks/blockspacerace/genesis.json $HOME/.celestia-app/config
```
## Add Seed
```
sed -i -e "s|^seeds *=.*|seeds = \"0293f2cf7184da95bc6ea6ff31c7e97578b9c7ff@65.109.106.95:26656\"|" $HOME/.celestia-app/config/config.toml
```

## Pruning Settings
```
PRUNING="nothing"
sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" $HOME/.celestia-app/config/app.toml
```

## Reset Network
```
celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app
```

## Start with Service
```
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-appd.service
[Unit]
Description=celestia-appd Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/celestia-appd start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
```
```
sudo systemctl enable celestia-appd
sudo systemctl start celestia-appd
```
- Log Control

```
sudo journalctl -u celestia-appd.service -f
```

- Waiting for the node to synchronise to the network. Check Block Number >>> https://tiascan.com/validators

## Celestia Bridge Node Installation
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

## Inıt Process
```
celestia bridge init --core.ip localhost --core.rpc.port 26657 --core.grpc.port 9090 --p2p.network blockspacerace
```

- Back up our wallet address and our words. 

- You can view your wallet with this code.
```
./cel-key list --node.type bridge --p2p.network blockspacerace
```

## Start with Service
```
sudo tee <<EOF >/dev/null /etc/systemd/system/celestia-bridge.service
[Unit]
Description=celestia-bridge Cosmos daemon
After=network-online.target

[Service]
User=$USER
ExecStart=/usr/local/bin/celestia bridge start --core.ip localhost --core.rpc.port 26657 --core.grpc.port 9090 --keyring.accname my_celes_key --metrics.tls=false --metrics --metrics.endpoint otel.celestia.tools:4318 --p2p.network blockspacerace
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
```
```
sudo systemctl enable celestia-bridge
sudo systemctl start celestia-bridge
```

- Log Control
```
sudo journalctl -u celestia-bridge.service -f
```

## Learning Node ID
```
AUTH_TOKEN=$(celestia bridge auth admin --p2p.network blockspacerace)
```
```
curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658
```
- When this code is entered, you will get a result like below ID="12D....." is your Node ID, you can find Uptime and other details by searching this on https://tiascan.com/bridge-nodes

![bbbbb](https://user-images.githubusercontent.com/73176377/229390894-94d0296b-e503-40b5-af1b-4bf59129dcc4.PNG)

- NOTE: You need to back up the keys folder under the .celestia-bridge-blockspacerace-0 folder with WinSCP or a tool with the same function.

