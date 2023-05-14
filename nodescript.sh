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
echo -e "\e[1m\e[32m Updates \e[0m" && sleep 2
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y && cd $HOME
sleep 1
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
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
echo -e "\e[1m\e[32m What is it you want to do? \e[0m" && sleep 2
PS3='Select an action: '
options=(
"Light Node Install"
"Bridge Node Install"
"Full Storage Node Install"
"Light Node Resetting Data"
"Bridge Node Resetting Data"
"Full Storage Resetting Data"
"What is Light Node ID?"
"What is Bridge Node ID?"
"What is Full Storage Node ID?"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Light Node Install")
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
echo "💥In this step, information about your wallet is shared. 💥PLEASE BACK UP THE MNEMONIC WORDS.💥 After backing up, you can continue by pressing the C key."
read C
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
journalctl -u celestia-lightd.service -f
break
;;

"Bridge Node Install")
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

sed -i -e "s|^seeds *=.*|seeds = \"0293f2cf7184da95bc6ea6ff31c7e97578b9c7ff@65.109.106.95:26656\"|" $HOME/.celestia-app/config/config.toml

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

echo "💥In this step, information about your wallet is shared.💥PLEASE BACK UP THE MNEMONIC WORDS.💥 After backing up, you can continue by pressing the C key."
read C

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
sudo journalctl -u celestia-bridge.service -f

break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
