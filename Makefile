.PHONY: deps db run start format docs credo check generate-protos generate-arena-protos generate-game-client-protos generate-arena-load-test-protos generate-bot-manager-protos

deps:
	cd apps/game_client/assets && npm install
	mix deps.get

db: deps
	mix ecto.reset

run:
	iex -S mix phx.server

start: db run

purge:
	rm -rf devenv.lock .devenv .devenv.flake.nix _build/
	devenv gc

format:
	mix format

credo:
	mix credo

check: credo format

docs:
	mix docs

generate-protos: generate-gateway-protos generate-arena-protos generate-game-client-protos generate-arena-load-test-protos generate-bot-manager-protos format

generate-gateway-protos:
	protoc \
		--elixir_out=apps/gateway/lib/gateway/serialization \
		--elixir_opt=package_prefix=gateway.serialization \
		--proto_path=apps/serialization \
		gateway.proto

generate-arena-protos:
	protoc \
		--elixir_out=apps/arena/lib/arena/serialization \
		--elixir_opt=package_prefix=arena.serialization \
		--proto_path=apps/serialization \
		messages.proto

generate-game-client-protos:
	protoc \
		--elixir_out=apps/game_client/lib/game_client/protobuf \
		--elixir_opt=package_prefix=game_client.protobuf \
		--proto_path=apps/serialization \
		messages.proto

	protoc \
		--js_out=import_style=commonjs:apps/game_client/assets/js/protobuf \
		--proto_path=apps/serialization \
		messages.proto

generate-arena-load-test-protos:
	protoc \
		--elixir_out=apps/arena_load_test/lib/arena_load_test/serialization \
		--elixir_opt=package_prefix=arena_load_test.serialization \
		--proto_path=apps/serialization \
		messages.proto

generate-bot-manager-protos:
	protoc \
		--elixir_out=apps/bot_manager/lib/protobuf \
		--elixir_opt=package_prefix=bot_manager.protobuf \
		--proto_path=apps/serialization \
		messages.proto

# INFRA
.PHONY: server-specs admin-setup-arena-server debian-install-deps setup-caddy create-env-file app-setup-arena-server debian-install-dev-deps
## Check server specs (loadtests)
server-specs:
	./devops/server_specs.sh

## New server. Setup dependencies.
## Run one of these (arena or central) as admin user

admin-setup-arena-server: debian-install-deps setup-caddy-arena create-env-file

admin-setup-central-server: debian-install-deps debian-setup-grafana setup-caddy-central setup-prometheus create-env-file

debian-install-deps:
	sudo apt update -y
	sudo apt install -y rsync libssl-dev libncurses5 libsctp1 wget systemd-timesyncd ufw
	wget -P /tmp/ http://ftp.de.debian.org/debian/pool/main/o/openssl/libssl1.1_1.1.1w-0+deb11u1_amd64.deb
	wget -P /tmp/ https://binaries2.erlang-solutions.com/debian/pool/contrib/e/esl-erlang/esl-erlang_26.2.3-1~debian~buster_amd64.deb
	wget -P /tmp/ https://github.com/elixir-lang/elixir/releases/download/v1.16.3/elixir-otp-26.zip
	cd ~/ \
	sudo dpkg -i /tmp/libssl1.1_1.1.1w-0+deb11u1_amd64.deb \
	sudo dpkg -i /tmp/esl-erlang_26.2.3-1~debian~buster_amd64.deb \
	sudo unzip -d /usr/ -qo /tmp/elixir-otp-26.zip
	rm /tmp/libssl1.1_1.1.1w-0+deb11u1_amd64.deb
	rm /tmp/esl-erlang_26.2.3-1~debian~buster_amd64.deb
	rm /tmp/elixir-otp-26.zip

create-env-file:
	sudo truncate -s0 /home/$(SSH_APP_USERNAME)/.env
	sudo echo "PHX_HOST=$$(hostname).championsofmirra.com" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "DATABASE_URL=$(DATABASE_URL)" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "CONFIGURATOR_DATABASE_URL=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "PHX_SERVER=true" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "SECRET_KEY_BASE=$(SECRET_KEY_BASE)" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "JWT_PRIVATE_KEY_BASE_64=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "PORT=4000" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "RELEASE_NODE=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "_SERVICE_SUFFIX=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "GATEWAY_URL=https://central-europe-testing.championsofmirra.com" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "METRICS_ENDPOINT_PORT=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "OVERRIDE_JWT=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "GOOGLE_CLIENT_ID=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "BOT_MANAGER_PORT=4003" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "BOT_MANAGER_HOST=bot-manager.championsofmirra.com" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "CONFIGURATOR_HOST=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "CONFIGURATOR_GOOGLE_CLIENT_ID=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "CONFIGURATOR_GOOGLE_CLIENT_SECRET=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "RELEASE=arena" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "TARGET_SERVER=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "LOADTEST_EUROPE_HOST=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "LOADTEST_BRAZIL_HOST=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "LOADTEST_CHILE_HOST=" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "NEWRELIC_APP_NAME=$$(hostname)" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "NEWRELIC_KEY=$(NEWRELIC_KEY)" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null
	sudo echo "LOADTEST_ALONE_MODE=$(LOADTEST_ALONE_MODE)" | sudo tee -a /home/$(SSH_APP_USERNAME)/.env > /dev/null

## ARENA SERVER ONLY

setup-caddy-arena:
	sudo ufw allow 80
	sudo ufw allow 443
	sudo truncate -s 0 /etc/caddy/Caddyfile && \
	echo "$$(hostname).championsofmirra.com {" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "  reverse_proxy localhost:4000" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "}" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	sudo sh -c 'echo "" >> /etc/caddy/Caddyfile'
	echo "$$(hostname).prometheus.championsofmirra.com {" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "  basicauth {" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "    $$(PROMETHEUS_USER) $$(PROMETHEUS_PASSWORD)" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "  }" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "  reverse_proxy localhost:9568" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "}" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	sudo sh -c 'echo "" >> /etc/caddy/Caddyfile'
	sudo systemctl restart caddy

## CENTRAL SERVER ONLY

debian-setup-grafana:
	wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
	sudo apt-get update
	sudo apt-get install grafana -y
	sudo systemctl enable grafana-server
	sudo systemctl start grafana-server

setup-prometheus:
	curl -s https://$(GATEWAY_URL)/api/arena_servers | \
	jq -r '.servers[].url | "          - \(. | sub("^arena-"; "arena-") + ".prometheus.championsofmirra.com")"' > /tmp/targets.txt && \
	echo "scrape_configs:" > /etc/prometheus/prometheus.yml && \
	echo "  - job_name: 'arena_servers'" >> /etc/prometheus/prometheus.yml && \
	echo "    scheme: https" >> /etc/prometheus/prometheus.yml && \
	echo "    metrics_path: '/metrics'" >> /etc/prometheus/prometheus.yml && \
	echo "    basic_auth:" >> /etc/prometheus/prometheus.yml && \
	echo "      username: $$(PROMETHEUS_USER)" >> /etc/prometheus/prometheus.yml && \
	echo "      password: $$(PROMETHEUS_PASSWORD)" >> /etc/prometheus/prometheus.yml && \
	echo "    static_configs:" >> /etc/prometheus/prometheus.yml && \
	echo "      - targets:" >> /etc/prometheus/prometheus.yml && \
	cat /tmp/targets.txt >> /etc/prometheus/prometheus.yml && \
	rm /tmp/targets.txt
	sudo systemctl restart prometheus

setup-central-caddy:
	sudo ufw allow 80
	sudo ufw allow 443
	sudo truncate -s 0 /etc/caddy/Caddyfile && \
	echo "$$(hostname).championsofmirra.com {" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "  reverse_proxy localhost:4000" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "}" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	sudo sh -c 'echo "" >> /etc/caddy/Caddyfile'
	sudo truncate -s 0 /etc/caddy/Caddyfile && \
	echo "$$(hostname).configurator.championsofmirra.com {" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "  reverse_proxy localhost:4100" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "}" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	sudo sh -c 'echo "" >> /etc/caddy/Caddyfile'
	echo "$$(hostname).grafana.championsofmirra.com {" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "  reverse_proxy localhost:3000" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	echo "}" | sudo tee -a /etc/caddy/Caddyfile > /dev/null && \
	sudo sh -c 'echo "" >> /etc/caddy/Caddyfile'
	sudo systemctl restart caddy

setup-aws-central-dns:
	@AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	AWS_REGION=us-west-2 \
	aws route53 change-resource-record-sets \
		--hosted-zone-id "Z10155211PTW2X4H9NGDM" \
		--change-batch "{\"Changes\":[{\"Action\":\"UPSERT\",\"ResourceRecordSet\":{\"Name\":\"$$(hostname).championsofmirra.com\",\"Type\":\"A\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"$$(curl -s ipinfo.io/ip)\"}]}}]}"

	@AWS_ACCESS_KEY_ID=$(AWS_ACCESS_KEY_ID) \
	AWS_SECRET_ACCESS_KEY=$(AWS_SECRET_ACCESS_KEY) \
	AWS_REGION=us-west-2 \
	aws route53 change-resource-record-sets \
		--hosted-zone-id "Z10155211PTW2X4H9NGDM" \
		--change-batch "{\"Changes\":[{\"Action\":\"UPSERT\",\"ResourceRecordSet\":{\"Name\":\"$$(hostname).grafana.championsofmirra.com\",\"Type\":\"A\",\"TTL\":300,\"ResourceRecords\":[{\"Value\":\"$$(curl -s ipinfo.io/ip)\"}]}}]}"


## Run this as app or dev user

app-setup-arena-server: debian-install-dev-deps

debian-install-dev-deps:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
