#!/bin/bash

# Fail if variables are unset
set -eu -o pipefail

echo '🚧 Check for configuration file'
if [ -f "./config.toml" ]; then
    echo "Hugo TOML configuration file found."
elif [ -f "./config.yaml" ]; then
    echo "Hugo YAML configuration file found."
elif [ -f "./config.json" ]; then
    echo "Hugo JSON configuration file found."
else
    echo "🛑 No valid Hugo configuration file found. Stopping." && exit 1
fi

echo '🔧 Install tools'
npm init -y && npm install -y postcss postcss-cli autoprefixer

echo '🤵 Install Hugo'
mkdir tmp/ && cd tmp/
curl -sSL $(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep "browser_download_url.*\hugo_extended.*\_Linux-64bit.tar.gz" | rev | cut -d ' ' -f 1 | rev | tr -d '"') | tar -xvzf-
mv hugo /usr/local/bin/
cd .. && rm -rf tmp/
cd ${GITHUB_WORKSPACE}
hugo version || exit 1

echo '👯 Clone remote repository'
git clone https://github.com/${REMOTE} ${DEST}

echo '🧹 Clean site'
if [ -d "${DEST}" ]; then
    rm -rf ${DEST}/*
fi

echo '🍳 Build site'
hugo ${HUGO_ARGS:-""} -d ${DEST}

echo '📡 generate CNAME file'
if [[ -n "${CUSTOM_DOMAIN:-}" && -n "${CUSTOM_DOMAIN}" ]]; then
    echo "${CUSTOM_DOMAIN}" > "${DEST}/CNAME"
fi

echo '🎁 Publish to remote repository'
COMMIT_MESSAGE=${INPUT_COMMIT_MESSAGE}
[ -z $COMMIT_MESSAGE ] && COMMIT_MESSAGE="🚀 Deploy with ${GITHUB_WORKFLOW}"

cd ${DEST}
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git add .
git commit -am "$COMMIT_MESSAGE"

CONTEXT=${INPUT_BRANCH}
[ -z $CONTEXT ] && CONTEXT='main'

git push -f -q https://${TOKEN}@github.com/${REMOTE} $CONTEXT
