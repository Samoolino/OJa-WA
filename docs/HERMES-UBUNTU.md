# OJa-WA Ubuntu + Hermes development environment

This is the handoff point from hosted CI development to an Ubuntu terminal with Hermes Agent. Keep secrets outside Git; use Hermes configuration and the local `.env` only on the machine.

## 1. Clone the repository

```bash
git clone https://github.com/Samoolino/OJa-WA.git ~/src/OJa-WA
cd ~/src/OJa-WA
git checkout main
git pull --ff-only
```

## 2. Install the Ubuntu prerequisites

```bash
sudo apt-get update
sudo apt-get install -y git curl xz-utils build-essential libpq-dev postgresql-client redis-tools
```

## 3. Install Hermes Agent

The official Hermes installer supports Linux/Ubuntu and installs its managed Python/Node/tooling environment:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
hermes doctor
```

Hermes stores secrets in `~/.hermes/.env` and normal configuration in `~/.hermes/config.yaml`. Do not commit either file.

## 4. Configure the model/provider

```bash
hermes model
hermes tools
```

Use a model with at least 64K context for this multi-step repository workflow.

## 5. Bootstrap OJa-WA

```bash
cd ~/src/OJa-WA
chmod +x scripts/bootstrap-ubuntu-hermes.sh
./scripts/bootstrap-ubuntu-hermes.sh
```

## 6. Local service requirements

OJa-WA development/test expects PostgreSQL and Redis. Preferred local values are:

```bash
export RAILS_ENV=test
export DATABASE_URL='postgres://postgres:postgres@127.0.0.1:5432/oja_wa_test'
```

Start/check PostgreSQL and Redis using the Ubuntu service or your existing local container stack. Do not place production credentials in this file.

## 7. Ruby/Bundler

Use the repository's `.ruby-version` when present. Then:

```bash
ruby --version
bundle --version
bundle config set --local path vendor/bundle
bundle install
```

## 8. Database bootstrap

```bash
RAILS_ENV=test bundle exec rails db:prepare
RAILS_ENV=test bundle exec rails db:migrate
```

The CI workflow deliberately migrates the extension schema before the financial-integrity suite. Keep local execution equivalent to CI.

## 9. G2 validation

Run the same financial suites used by CI:

```bash
RAILS_ENV=test bundle exec rspec spec/services/spree/allocation_financial_integrity_spec.rb
RAILS_ENV=test bundle exec rspec spec/services/spree/payment_capture_spec.rb
RAILS_ENV=test bundle exec rspec spec/services/spree/order_lifecycle_integrity_spec.rb
RAILS_ENV=test bundle exec rspec spec/services/spree/g2_transaction_path_spec.rb
```

Do not advance to endpoint execution solely because the application boots. G2 must exercise funding, allocation, capture, reconciliation, fulfillment, settlement, and refund/reversal.

## 10. Hermes operating boundary

Use Hermes for repository inspection, implementation, tests, migrations, and Git operations. Keep production credentials, Stripe secrets, SSH keys, and deployment credentials outside the repository and outside prompts whenever possible.

Recommended first Hermes session:

```text
Work in ~/src/OJa-WA. Read docs/HERMES-UBUNTU.md first. Inspect the current git status and recent commits. Reproduce the G2 CI gate locally before changing application code. Make the smallest evidence-based correction for the first failing test, run the affected test, then the full G2 suite. Do not claim G2 certification unless all required tests pass.
```

## 11. Handoff checkpoint

The hosted implementation remains the source of truth until the Ubuntu environment reproduces the same G2 result. Record the local commit SHA and test output before moving to endpoint execution.
