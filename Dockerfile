FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y && apt-get install apt-utils curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

ENV HOME=/app

WORKDIR /app

ENV GO_VER="1.22.5"

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
rm "go$GO_VER.linux-amd64.tar.gz" && \
mkdir -p ~/go/bin

ENV PATH="/usr/local/go/bin:~/go/bin:${PATH}"
ENV WALLET="wallet"
ENV MONIKER="Stake Shark"
ENV WARDEN_CHAIN_ID="chiado_10010-1"
ENV WARDEN_PORT="18"

RUN rm -rf bin && \
mkdir bin && cd bin && \
wget https://github.com/warden-protocol/wardenprotocol/releases/download/v0.5.2/wardend_Linux_x86_64.zip && \
unzip wardend_Linux_x86_64.zip && \
chmod +x wardend && \
mv $HOME/bin/wardend $HOME/go/bin && \
rm -rf wardend_Linux_x86_64.zip

ENV SEEDS="8288657cb2ba075f600911685670517d18f54f3b@warden-testnet-seed.itrocket.net:18656"
ENV PEERS="b14f35c07c1b2e58c4a1c1727c89a5933739eeea@warden-testnet-peer.itrocket.net:18656,c4062d4d78bdba923ae72c32876f99aaa736f846@84.247.141.90:26656,be9d2a009589d3d7194ad66a3baf66fc47a87033@144.76.97.251:26726,eb2e7095f86b24e8d5d286360c34e060a8db6334@188.40.85.207:12756,59466aee103eae0640a51181532e264478ec059c@65.109.70.11:19656,8f50605a5cd64c735f86ffc22f2dd0177bcc58b3@168.119.120.156:26656,7b26de79a9d13e74987d1053055f1c88502ec852@149.50.102.86:11956,bf7535ad07768789e61866eb0af5499162350e73@173.249.3.156:18656,2f99ac7e72cc8c1f951e027d6088b8a920163237@65.109.111.234:18656,e9ce3a2e63fb052a802ca17c809d2f2da6795a2a@65.108.235.189:19956,5784d5d85cc85c75b60287967f60ae928eb57e68@144.76.112.58:23656"

RUN wardend init $MONIKER && \
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${WARDEN_PORT}657\"|" $HOME/.warden/config/client.toml && \
sed -i -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*seeds *=.*/seeds = \"$SEEDS\"/}" -e "/^\[p2p\]/,/^\[/{s/^[[:space:]]*persistent_peers *=.*/persistent_peers = \"$PEERS\"/}" $HOME/.warden/config/config.toml && \
sed -i.bak -e "s%:1317%:${WARDEN_PORT}317%g; \
s%:8080%:${WARDEN_PORT}080%g; \
s%:9090%:${WARDEN_PORT}090%g; \
s%:9091%:${WARDEN_PORT}091%g; \
s%:8545%:${WARDEN_PORT}545%g; \
s%:8546%:${WARDEN_PORT}546%g; \
s%:6065%:${WARDEN_PORT}065%g" $HOME/.warden/config/app.toml && \
sed -i.bak -e "s%:26658%:${WARDEN_PORT}658%g; \
s%:26657%:${WARDEN_PORT}657%g; \
s%:6060%:${WARDEN_PORT}060%g; \
s%:26656%:${WARDEN_PORT}656%g; \
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${WARDEN_PORT}656\"%; \
s%:26660%:${WARDEN_PORT}660%g" $HOME/.warden/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.warden/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.warden/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.warden/config/app.toml && \
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "25000000award"|g' $HOME/.warden/config/app.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.warden/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.warden/config/config.toml

RUN wget -O $HOME/.warden/config/genesis.json https://server-4.itrocket.net/testnet/warden/genesis.json && \
wget -O $HOME/.warden/config/addrbook.json  https://server-4.itrocket.net/testnet/warden/addrbook.json

ENTRYPOINT ["wardend", "start", "--home", "/home/ubuntu/.warden"]
