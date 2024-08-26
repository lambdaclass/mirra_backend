#!/usr/bin/env bash
. "${HOME}/.cargo/env"
set -ex

export PATH=${PATH}:/opt/homebrew/bin/

if [ -d "/tmp/mirra_backend" ]; then
	rm -rf /tmp/mirra_backend
fi

cd /tmp
git clone git@github.com:lambdaclass/mirra_backend.git --branch ${BRANCH_NAME} mirra_backend
cd mirra_backend

chmod +x devops/entrypoint.sh

mix local.hex --force && mix local.rebar --force
mix deps.get --only $MIX_ENV
MIX_ENV=$MIX_ENV mix compile
MIX_ENV=$MIX_ENV mix tailwind configurator --minify
MIX_ENV=$MIX_ENV mix esbuild configurator --minify
MIX_ENV=$MIX_ENV mix phx.digest
mix release ${RELEASE} --overwrite
if [ ${RELEASE} == "central_backend" ]; then
	mix ecto.migrate
fi

rm -rf ${HOME}/arena/mirra_backend
mv /tmp/mirra_backend ${HOME}/arena/

mkdir -p ${HOME}/.config/systemd/user/

cat <<EOF >${HOME}/Library/LaunchAgents/${RELEASE}.plist
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.lambdaclass.${RELEASE}</string>

        <key>ServiceDescription</key>
        <string>Arena</string>

        <key>Program</key>
        <string>${HOME}/arena/mirra_backend/devops/entrypoint-macos.sh</string>

        <key>WorkingDirectory</key>
        <string>${HOME}/arena/mirra_backend</string>

        <key>StandardOutputPath</key>
        <string>${HOME}/arena/arena.log</string>

        <key>StandardErrorPath</key>
        <string>${HOME}/arena/arena.log</string>

        <key>EnvironmentVariables</key>
        <dict>
            <key>PHX_HOST</key>
            <string>
                ${PHX_HOST}
            </string>
            <key>DATABASE_URL</key>
            <string>
                ${DATABASE_URL}
            </string>
            <key>PHX_SERVER</key>
            <string>
                ${PHX_SERVER}
            </string>
            <key>SECRET_KEY_BASE</key>
            <string>
                ${SECRET_KEY_BASE}
            </string>
            <key>JWT_PRIVATE_KEY_BASE_64</key>
            <string>
                ${JWT_PRIVATE_KEY_BASE_64}
            </string>
            <key>PORT</key>
            <string>
                ${PORT}
            </string>
            <key>RELEASE_NODE</key>
            <string>
                ${RELEASE_NODE}
            </string>
            <key>GATEWAY_URL</key>
            <string>
                ${GATEWAY_URL}
            </string>
            <key>METRICS_ENDPOINT_PORT</key>
            <string>
                ${METRICS_ENDPOINT_PORT}
            </string>
            <key>OVERRIDE_JWT</key>
            <string>
                ${OVERRIDE_JWT}
            </string>
            <key>GOOGLE_CLIENT_ID</key>
            <string>
                ${GOOGLE_CLIENT_ID}
            </string>
            <key>BOT_MANAGER_PORT</key>
            <string>
                ${BOT_MANAGER_PORT}
            </string>
            <key>BOT_MANAGER_HOST</key>
            <string>
                ${BOT_MANAGER_HOST}
            </string>
            <key>CONFIGURATOR_HOST</key>
            <string>
                ${CONFIGURATOR_HOST}
            </string>
            <key>CONFIGURATOR_GOOGLE_CLIENT_ID</key>
            <string>
                ${CONFIGURATOR_GOOGLE_CLIENT_ID}
            </string>
            <key>CONFIGURATOR_GOOGLE_CLIENT_SECRET</key>
            <string>
                ${CONFIGURATOR_GOOGLE_CLIENT_SECRET}
            </string>
            <key>RELEASE</key>
            <string>
                ${RELEASE}
            </string>
            <key>TARGET_SERVER</key>
            <string>
                ${TARGET_SERVER}
            </string>
            <key>LOADTEST_EUROPE_HOST</key>
            <string>
                ${LOADTEST_EUROPE_HOST}
            </string>
            <key>LOADTEST_BRAZIL_HOST</key>
            <string>
                ${LOADTEST_BRAZIL_HOST}
            </string>
        </dict>

        <key>RunAtLoad</key>
        <false />
    </dict>
</plist>
EOF

launchctl unload ${HOME}/Library/LaunchAgents/${RELEASE}.plist || true
launchctl load ${HOME}/Library/LaunchAgents/${RELEASE}.plist
launchctl start com.lambdaclass.${RELEASE}
