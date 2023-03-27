## Sistem Gereksinimleri
- Memory: 2 GB RAM
- CPU: Single Core
- Disk: 5 GB SSD

## Tmux Kullanımı (Servis kullanacaksanız gerek yok)
- Yeni tmux tekranı açmak: ```tmux```
- Tmux ekranı listelemek: ```tmux ls```
- Önceden açılmış tmux ekranını açmak: ```tmux attach -t tmuxsayfaismi```
- Tmux sayfasından çıkmak:``ctrl+b`` basıp sonra sadece ``d`` ye basmak

## Sistem Güncellemesi
```
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential git ncdu -y
sudo apt install make -y
```

## Go Yüklüyoruz
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

- ``go version`` yazdığınızda ``go version go1.20 linux/amd64`` sonucunu vermesi gerekiyor.

## Celestia Light Node Yükleme
```
cd $HOME 
rm -rf celestia-node 
git clone https://github.com/celestiaorg/celestia-node.git 
cd celestia-node/ 
git checkout tags/v0.8.0-rc0 
make build 
make install 
make cel-key 
```

- ``celestia version`` yazdığımızda aşağıdaki çıktıyı almalıyız.
```
Semantic version: v0.8.0-rc0
Commit: 09cf0043b199f2a329b71b3895ab32c2b42cece3
Build Date: Mon 27 Mar 2023 09:01:53 PM UTC
System version: amd64/linux
Golang version: go1.20 
```

## Inıt İşlemi
- Komut girildiğinde my_celes_key adında yeni bir cüzdan oluşacak. Bu cüzdanın adresini ve mnemoniclerini kaydetmeyi unutmayın!
```
celestia light init --p2p.network blockspacerace
```
- Üstteki komut girildiğinde aşağıdaki gibi bir sonuç vermelidir.
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

## Standart Başlatma 
- Tmux ekranındayken aşağıdaki kod girilir.
```
celestia light start --core.ip https://rpc-blockspacerace.pops.one --core.rpc.port 26657 --core.grpc.port 9090 --keyring.accname my_celes_key --metrics.tls=false --metrics --metrics.endpoint otel.celestia.tools:4318 --gateway --gateway.addr localhost --gateway.port 26659 --p2p.network blockspacerace
```

## Servis İle Başlatmak
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
- Sisteme eşitlendikten sonra loglar aşağıdakilere benzer şekilde görünmelidir.
```
INFO    header/store    store/store.go:349      new head        {"height": 106151, "hash": "CD084A85460978EC8C9E4BA23EE3847B28A90A879245E46F68B8133E413EA7A3"}
INFO    das     das/subscriber.go:34    new header received via subscription    {"height": 106151}
INFO    das     das/worker.go:79        finished sampling headers       {"from": 106151, "to": 106151, "errors": 0, "finished (s)": 0.000060704}
WARN    header/sync     sync/sync_head.go:140   received known network header   {"current_height": 106151, "header_height": 106151, "header_hash": "CD084A85460978EC8C9E4BA23EE3847B28A90A879245E46F68B8133E413EA7A3"}
INFO    header/store    store/store.go:349      new head        {"height": 106152, "hash": "C0FA44EF29FDE75ECD069A2031CC0A8BE94996F775FC106F76B88CCA514B1EF9"}
INFO    das     das/subscriber.go:34    new header received via subscription    {"height": 106152}
INFO    das     das/worker.go:79        finished sampling headers       {"from": 106152, "to": 106152, "errors": 0, "finished (s)": 0.00005358}
```
## Node ID Öğrenmek
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
- Bu kod girildiğinde aşağıdaki gibi bir sonuç alacaksınız ID="12D....." yazan değer sizin Node ID'niz, bunu da https://tiascan.com/light-nodes sitesinde aratarak Uptime ve diğer ayrıntılara ulaşabilirsiniz.
![11111](https://user-images.githubusercontent.com/73176377/228071707-5f6639e6-b51c-48a9-957a-33a317f5653b.PNG)
