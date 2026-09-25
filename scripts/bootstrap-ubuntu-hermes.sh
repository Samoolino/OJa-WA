#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v git >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y git
fi

sudo apt-get update
sudo apt-get install -y curl xz-utils build-essential libpq-dev postgresql-client redis-tools

if ! command -v hermes >/dev/null 2>&1; then
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
fi

export PATH="$HOME/.local/bin:$PATH"

if ! command -v hermes >/dev/null 2>&1; then
  echo "Hermes installed but is not on PATH. Add: export PATH=\"$HOME/.local/bin:$PATH\""
  exit 1
fi

hermes doctor || true

if [ -f .ruby-version ]; then
  echo "Ruby requested by repository: $(cat .ruby-version)"
fi

if command -v ruby >/dev/null 2>&1; then
  ruby --version
fi

if command -v bundle >/dev/null 2>&1; then
  bundle --version
fi

if [ -f Gemfile ]; then
  bundle config set --local path vendor/bundle
  bundle install
fi

echo
echo "OJa-WA + Hermes Ubuntu bootstrap complete."
echo "Repository: $REPO_ROOT"
echo "Start Hermes with: hermes"
echo "Run diagnostics with: hermes doctor"
echo "Run the repository integrity workflow locally with the commands in docs/HERMES-UBUNTU.md"
