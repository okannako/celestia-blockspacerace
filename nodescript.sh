#!/bin/bash
echo -e "\033[0;37m"
echo "============================================================================================================"
echo " #####   ####        ####        ####  ####    ######    ##########  ####    ####  ###########   ####  ####"
echo " ######  ####       ######       #### ####    ########   ##########  ####    ####  ####   ####   #### ####"
echo " ####### ####      ###  ###      ########    ####  ####     ####     ####    ####  ####   ####   ########"   
echo " #### #######     ##########     ########   ####    ####    ####     ####    ####  ###########   ########"
echo " ####  ######    ############    #### ####   ####  ####     ####     ####    ####  ####  ####    #### ####"  
echo " ####   #####   ####      ####   ####  ####   ########      ####     ############  ####   ####   ####  ####"
echo " ####    ####  ####        ####  ####   ####    ####        ####     ############  ####    ####  ####   ####"
echo "============================================================================================================"
echo -e '\e[36mTwitter :\e[39m' https://twitter.com/NakoTurk
echo -e '\e[36mGithub  :\e[39m' https://github.com/okannako
echo -e '\e[36mYoutube :\e[39m' https://www.youtube.com/@CryptoChainNakoTurk
echo -e "\e[0m"
sleep 5

echo -e "\e[1m\e[32m What is it you want to do? \e[0m" && sleep 2
PS3='Select an action: '
options=(
"Validator Node Install"
"Validator Node Control"
"Create Validator"
"Light Node Install"
"Bridge Node Install"
"Full Storage Node Install"
"Light Node Resetting Data"
"Bridge Node Resetting Data"
"Full Storage Node Resetting Data"
"What is Light Node ID?"
"What is Bridge Node ID?"
"What is Full Storage Node ID?"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Validator Node Install")

echo -e "\e[1m\e[32m Updates \e[0m" && sleep 2
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y && cd $HOME
sleep 1

echo -e "\e[1m\e[32m Install Go \e[0m" && sleep 2
ver="1.20.3"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version && sleep 2

cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v0.13.0
git checkout tags/$APP_VERSION -b $APP_VERSION 
make install
celestia-appd && sleep 3

echo "NodeName:"
read NodeName
echo export NodeName=${NodeName} >> $HOME/.bash_profile

celestia-appd init "$NodeName" --chain-id blockspacerace-0

cp $HOME/networks/blockspacerace/genesis.json $HOME/.celestia-app/config

peers="b766d36a1e3bcefc5e5befddfad7b4589ba28a21@162.55.242.83:26656,c97019ef9ee43e93ad9019514b612e6b8363c3fd@138.201.63.38:26686,62f6abc162db99389f13a1cdf1abaeb6efb647a7@35.210.78.75:26656,6c73374cb78a543e2dd3eb218c29386392da2cf5@35.210.99.77:26656,5fa6853eb52bc3a5ff1fe56b988515d16644819a@65.21.232.33:2000,de36dc2bc32ecaacafb213d173f6218f93ebb306@144.76.105.14:26656,ae95e8d93a0822a763823551c163d15d4cdce944@116.202.227.117:20656,af66f28f19f747bd2b5a18d91d143dc8e035f86a@47.147.226.228:52656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:12056,0196b56324c6fd3dd31110d3cb06dc169a1e1310@194.62.97.31:26656"
sed -i 's|^seeds *=.*|seeds = "'$SEEDS'"|; s|^persistent_peers *=.*|persistent_peers = "'$PEERS'"|' $HOME/.celestia-app/config/config.toml

PRUNING="nothing"
sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" $HOME/.celestia-app/config/app.toml

celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app

echo -e "\e[1m\e[32m Downloading Snapshot for fast synchronisation to the current block. \e[0m" && sleep 2
curl -L https://snapshots.kjnodes.com/celestia-testnet/snapshot_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.celestia-app
[[ -f $HOME/.celestia-app/data/upgrade-info.json ]] && cp $HOME/.celestia-app/data/upgrade-info.json $HOME/.celestia-app/cosmovisor/genesis/upgrade-info.json

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

sudo systemctl enable celestia-appd
sudo systemctl start celestia-appd

echo "WalletName:"
read WalletName
echo export WalletName=${WalletName} >> $HOME/.bash_profile
celestia-appd keys add $WalletName

echo -e '\e[36mIn this step, information about your wallet is shared. >>>PLEASE BACK UP THE MNEMONIC WORDS.<<< After backing up, you can continue by pressing the Enter key.\e[39m'
read Enter

echo -e '\e[36mIMPORTANT: Wait for synchronisation to the current block. To check, restart the script and select the relevant option.\e[39m'
sleep 7
sudo journalctl -u celestia-appd -f

break
;;

"Validator Node Control")

celestia-appd tx staking create-validator \
--amount=1000000utia \
--pubkey=$(celestia-appd tendermint show-validator) \
--moniker="$NodeName" \
--chain-id=blockspacerace-0 \
--commission-rate=0.05 \
--commission-max-rate=0.20 \
--commission-max-change-rate=0.01 \
--min-self-delegation=1 \
--from=$WalletName \
--gas-adjustment=1.4 \
--gas=auto \
--gas-prices=0.0"utia

echo -e '\e[36mIMPORTANT: After the validator creation step is finished, be sure to back up the config folder in the .celestia-appd folder.\e[39m'
sleep 10

break
;;

"Create Validator")

celestia-appd status 2>&1 | jq .SyncInfo
echo -e '\e[36mIMPORTANT: When "catching_up": false, you have accessed the current block and you can run the script again and Create Validator. Before creating a validator, be sure to request a test token on Discord to your wallet.\e[39m'
sleep 10

break
;;

"Light Node Install")

echo -e "\e[1m\e[32m Updates \e[0m" && sleep 2
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y && cd $HOME
sleep 1

echo -e "\e[1m\e[32m Install Go \e[0m" && sleep 2
ver="1.20.3"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version && sleep 2

cd $HOME 
rm -rf celestia-node 
git clone https://github.com/celestiaorg/celestia-node.git 
cd celestia-node/ 
git checkout tags/v0.9.4
make build 
make install 
make cel-key
celestia version && sleep 3
celestia light init --p2p.network blockspacerace

echo -e '\e[36mIn this step, information about your wallet is shared. >>>PLEASE BACK UP THE MNEMONIC WORDS.<<< After backing up, you can continue by pressing the Enter key.\e[39m'
read Enter

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
systemctl enable celestia-lightd
systemctl start celestia-lightd

echo -e '\e[36mIMPORTANT: /root/.celestia-light-blockspacerace-0 under the keys folder must be backed up.\e[39m'
sleep 7

journalctl -u celestia-lightd.service -f

break
;;

"Bridge Node Install")

echo -e "\e[1m\e[32m Updates \e[0m" && sleep 2
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y && cd $HOME
sleep 1

echo -e "\e[1m\e[32m Install Go \e[0m" && sleep 2
ver="1.20.3"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version && sleep 2

cd $HOME 
rm -rf celestia-app 
git clone https://github.com/celestiaorg/celestia-app.git 
cd celestia-app/ 
APP_VERSION=v0.13.0 
git checkout tags/$APP_VERSION -b $APP_VERSION
make install
celestia-appd version && sleep 3

cd $HOME
rm -rf networks
git clone https://github.com/celestiaorg/networks.git

echo "NodeName:"
read NodeName
echo export NodeName=${NodeName} >> $HOME/.bash_profile

celestia-appd init "$NodeName" --chain-id blockspacerace-0

cp $HOME/networks/blockspacerace/genesis.json $HOME/.celestia-app/config

peers="b766d36a1e3bcefc5e5befddfad7b4589ba28a21@162.55.242.83:26656,c97019ef9ee43e93ad9019514b612e6b8363c3fd@138.201.63.38:26686,62f6abc162db99389f13a1cdf1abaeb6efb647a7@35.210.78.75:26656,6c73374cb78a543e2dd3eb218c29386392da2cf5@35.210.99.77:26656,5fa6853eb52bc3a5ff1fe56b988515d16644819a@65.21.232.33:2000,de36dc2bc32ecaacafb213d173f6218f93ebb306@144.76.105.14:26656,ae95e8d93a0822a763823551c163d15d4cdce944@116.202.227.117:20656,af66f28f19f747bd2b5a18d91d143dc8e035f86a@47.147.226.228:52656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:12056,0196b56324c6fd3dd31110d3cb06dc169a1e1310@194.62.97.31:26656"
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$peers\"|" $HOME/.celestia-app/config/config.toml

PRUNING="nothing"
sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" $HOME/.celestia-app/config/app.toml

celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app

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

sudo systemctl enable celestia-appd
sudo systemctl start celestia-appd

echo -e '\e[36mIMPORTANT: /root/.celestia-appd under the config folder must be backed up.\e[39m'
sleep 7

cd $HOME 
rm -rf celestia-node 
git clone https://github.com/celestiaorg/celestia-node.git 
cd celestia-node/ 
git checkout tags/v0.9.4 
make build 
make install 
make cel-key 
celestia version && sleep 3

celestia bridge init --core.ip localhost --core.rpc.port 26657 --core.grpc.port 9090 --p2p.network blockspacerace

echo -e '\e[36mIn this step, information about your wallet is shared. >>>PLEASE BACK UP THE MNEMONIC WORDS.<<< After backing up, you can continue by pressing the Enter key.\e[39m'
read Enter

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

sudo systemctl enable celestia-bridge
sudo systemctl start celestia-bridge


echo -e '\e[36mIMPORTANT: /root/.celestia-bridge-blockspacerace-0 under the keys folder must be backed up.\e[39m'
sleep 7

sudo journalctl -u celestia-bridge.service -f

break
;;

"Full Storage Node Install")

echo -e "\e[1m\e[32m Updates \e[0m" && sleep 2
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y && cd $HOME
sleep 1

echo -e "\e[1m\e[32m Install Go \e[0m" && sleep 2
ver="1.20.3"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
source $HOME/.bash_profile
go version && sleep 2

cd $HOME 
rm -rf celestia-node 
git clone https://github.com/celestiaorg/celestia-node.git 
cd celestia-node/ 
git checkout tags/v0.9.4 
make build 
make install 
make cel-key 
celestia version && sleep 3

celestia full init --p2p.network blockspacerace

echo -e '\e[36mIn this step, information about your wallet is shared. >>>PLEASE BACK UP THE MNEMONIC WORDS.<<< After backing up, you can continue by pressing the Enter key.\e[39m'
read Enter

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

systemctl enable celestia-fulld
systemctl start celestia-fulld


echo -e '\e[36mIMPORTANT: /root/.celestia-full-blockspacerace-0 under the keys folder must be backed up.\e[39m'
sleep 7

journalctl -u celestia-fulld.service -f

break
;;

"Light Node Resetting Data")

systemctl stop celestia-lightd
celestia light unsafe-reset-store --p2p.network blockspacerace
systemctl restart celestia-lightd
journalctl -u celestia-lightd.service -f

break
;;

"Bridge Node Resetting Data")

sudo systemctl stop celestia-bridge
celestia bridge unsafe-reset-store --p2p.network blockspacerace
sudo systemctl restart celestia-bridge
sudo journalctl -u celestia-bridge.service -f

break
;;

"Full Storage Node Resetting Data")

systemctl stop celestia-fulld
celestia full unsafe-reset-store --p2p.network blockspacerace
systemctl restart celestia-fulld
journalctl -u celestia-fulld.service -f

break
;;

"What is Light Node ID?")

AUTH_TOKEN=$(celestia light auth admin --p2p.network blockspacerace)

curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658

break
;;

"What is Bridge Node ID?")

AUTH_TOKEN=$(celestia bridge auth admin --p2p.network blockspacerace)

curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658

break
;;

"What is Full Storage Node ID?")

AUTH_TOKEN=$(celestia full auth admin --p2p.network blockspacerace)

curl -X POST \
     -H "Authorization: Bearer $AUTH_TOKEN" \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","id":0,"method":"p2p.Info","params":[]}' \
     http://localhost:26658

break
;;

"Exit")
exit
;;
*) echo "Run the script again for options.";;
esac
done
