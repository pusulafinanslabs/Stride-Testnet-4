#!/bin/bash

echo -e ''
echo -e '\e[0;36m'
echo -e '______________                                                                                      _________________                                                                            '
echo -e '|   _______   |                                                                                     |   _____________|                                                                           '
echo -e '|  |       |  |                                                                                     |   |                                                                                        '
echo -e '|  |       |  |   __         __   ______________     __         __     __           ______________  |   |              ___  _______     ____   ______________  _______     ____  ______________  '
echo -e '|  |_______|  |  |  |       |  |  |   __________|   |  |       |  |   |  |          |  ________  |  |   |__________    |  | |      \    |  |   |  ________  |  |      \    |  |  |   __________| '
echo -e '|  ___________|  |  |       |  |  |  |              |  |       |  |   |  |          |  |      |  |  |    __________|   |__| |  |\   \   |  |   |  |      |  |  |  |\   \   |  |  |  |            '
echo -e '|  |             |  |       |  |  |  |__________    |  |       |  |   |  |          |  |______|  |  |   |              ___  |  | \   \  |  |   |  |______|  |  |  | \   \  |  |  |  |__________  '
echo -e '|  |             |  |       |  |  |__________   |   |  |       |  |   |  |          |  _______   |  |   |              |  | |  |  \   \ |  |   |  _______   |  |  |  \   \ |  |  |__________   | '
echo -e '|  |             |  |       |  |             |  |   |  |       |  |   |  |          |  |      |  |  |   |              |  | |  |   \   \|  |   |  |      |  |  |  |   \   \|  |             |  | '
echo -e '|  |             |  |_______|  |   __________|  |   |  |_______|  |   |  |_______   |  |      |  |  |   |              |  | |  |    \      |   |  |      |  |  |  |    \      |   __________|  | '
echo -e '|__|             |_____________|  |_____________|   |_____________|   |__________|  |__|      |__|  |___|              |__| |__|     \_____|   |__|      |__|  |__|     \_____|  |_____________| '
echo -e '\e[0m'
echo -e ''
sleep 2
# set vars
if [ ! $NODENAME ]; then
	read -p "Node İsminizi Girin: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
STRIDE_PORT=16
if [ ! $WALLET ]; then
	echo "export WALLET=wallet" >> $HOME/.bash_profile
fi
echo "export STRIDE_CHAIN_ID=STRIDE-TESTNET-4" >> $HOME/.bash_profile
echo "export STRIDE_PORT=${STRIDE_PORT}" >> $HOME/.bash_profile
source $HOME/.bash_profile
echo '================================================='
echo -e "Node İsminiz: \e[1m\e[32m$NODENAME\e[0m"
echo -e "Cüzdan İsminiz: \e[1m\e[32m$WALLET\e[0m"
echo -e "Ağ Bilginiz: \e[1m\e[32m$STRIDE_CHAIN_ID\e[0m"
echo -e "Port Numaranız: \e[1m\e[32m$STRIDE_PORT\e[0m"
echo '================================================='
sleep 2
echo -e "\e[1m\e[32m1. Paketler Yükleniyor... \e[0m" && sleep 1
# update
sudo apt update && sudo apt upgrade -y
echo -e "\e[1m\e[32m2. Yüklemeler Tamamlanıyor... \e[0m" && sleep 1
# packages
sudo apt install curl build-essential git wget jq make gcc tmux chrony -y
# Go Kurulumu
if ! [ -x "$(command -v go)" ]; then
  ver="1.18.2"
  cd $HOME
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
  rm "go$ver.linux-amd64.tar.gz"
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
fi
echo -e "\e[1m\e[32m3. Binary Dosyası indiriliyor... \e[0m" && sleep 1
# download binary
cd $HOME
git clone https://github.com/Stride-Labs/stride.git
cd stride
git checkout cf4e7f2d4ffe2002997428dbb1c530614b85df1b
make build
sudo cp $HOME/stride/build/strided /usr/local/bin
# config
strided config chain-id $STRIDE_CHAIN_ID
strided config keyring-backend test
strided config node tcp://localhost:${STRIDE_PORT}657
# init
strided init $NODENAME --chain-id $STRIDE_CHAIN_ID
# download genesis and addrbook
wget -qO $HOME/.stride/config/genesis.json "https://raw.githubusercontent.com/Stride-Labs/testnet/main/poolparty/genesis.json"
# set peers and seeds
SEEDS="d2ec8f968e7977311965c1dbef21647369327a29@seedv2.poolparty.stridenet.co:26656"
PEERS="2771ec2eeac9224058d8075b21ad045711fe0ef0@34.135.129.186:26656,a3afae256ad780f873f85a0c377da5c8e9c28cb2@54.219.207.30:26656,328d459d21f82c759dda88b97ad56835c949d433@78.47.222.208:26639,bf57701e5e8a19c40a5135405d6757e5f0f9e6a3@143.244.186.222:16656,f93ce5616f45d6c20d061302519a5c2420e3475d@135.125.5.31:54356"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.stride/config/config.toml
# set custom ports
sed -i.bak -e "s%^proxy_app = \"tcp://127.0.0.1:26658\"%proxy_app = \"tcp://127.0.0.1:${STRIDE_PORT}658\"%; s%^laddr = \"tcp://127.0.0.1:26657\"%laddr = \"tcp://127.0.0.1:${STRIDE_PORT}657\"%; s%^pprof_laddr = \"localhost:6060\"%pprof_laddr = \"localhost:${STRIDE_PORT}060\"%; s%^laddr = \"tcp://0.0.0.0:26656\"%laddr = \"tcp://0.0.0.0:${STRIDE_PORT}656\"%; s%^prometheus_listen_addr = \":26660\"%prometheus_listen_addr = \":${STRIDE_PORT}660\"%" $HOME/.stride/config/config.toml
sed -i.bak -e "s%^address = \"tcp://0.0.0.0:1317\"%address = \"tcp://0.0.0.0:${STRIDE_PORT}317\"%; s%^address = \":8080\"%address = \":${STRIDE_PORT}080\"%; s%^address = \"0.0.0.0:9090\"%address = \"0.0.0.0:${STRIDE_PORT}090\"%; s%^address = \"0.0.0.0:9091\"%address = \"0.0.0.0:${STRIDE_PORT}091\"%" $HOME/.stride/config/app.toml
# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="50"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.stride/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.stride/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.stride/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.stride/config/app.toml
# set minimum gas price and timeout commit
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0ustrd\"/" $HOME/.stride/config/app.toml
# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.stride/config/config.toml
# reset
strided tendermint unsafe-reset-all --home $HOME/.stride
echo -e "\e[1m\e[32m4. Servis Başlatılıyor... \e[0m" && sleep 1
# create service
sudo tee /etc/systemd/system/strided.service > /dev/null <<EOF
[Unit]
Description=stride
After=network-online.target
[Service]
User=$USER
ExecStart=$(which strided) start --home $HOME/.stride
Restart=on-failure
RestartSec=3
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF
# start service
sudo systemctl daemon-reload
sudo systemctl enable strided
sudo systemctl restart strided
echo '=============== Yükleme, Başarıyla Tamamlandı. ==================='
echo -e 'Log Kontrol: \e[1m\e[32mjournalctl -u strided -f -o cat\e[0m'
echo -e "Sync Durumu: \e[1m\e[32mcurl -s localhost:${STRIDE_PORT}657/status | jq .result.sync_info\e[0m"
