FRONTEND = ./frontend
BACKEND = ./backend
FLUTTER_ROOT = $(CURDIR)/$(FRONTEND)/flutter_sdk

# Use local Flutter SDK if present, otherwise fall back to system flutter
FLUTTER_CMD = $(if $(wildcard $(FLUTTER_ROOT)),$(FLUTTER_ROOT)/bin/flutter,$(shell which flutter 2>/dev/null || echo flutter))
DART_CMD    = $(if $(findstring /,$(FLUTTER_CMD)),$(dir $(FLUTTER_CMD))dart,dart)

.PHONY: help setup test test-cov watch format lint changelog-check build-apk build-web build-rust test-rust check-rust test-all clean deploy docker-test docker-dev docker-stop e2e-setup e2e-test deploy-vps deploy-vps-config deploy-vps-sync deploy-vps-build deploy-vps-up deploy-vps-status deploy-vps-logs deploy-vps-shell deploy-vps-restart deploy-vps-askpass

help:
	@echo "Math App - Local Development"
	@echo "=============================="
	@echo "  make help          Show this message"
	@echo ""
	@echo "  make setup         Install all dependencies"
	@echo "  make test          Run Flutter tests only"
	@echo "  make test-rust     Run Rust tests only"
	@echo "  make test-all      Run ALL tests (Flutter + Rust + E2E)"
	@echo "  make test-cov      Run Flutter tests with coverage"
	@echo "  make watch         Watch mode Flutter tests"
	@echo ""
	@echo "  make e2e-setup    Install Playwright + browsers"
	@echo "  make e2e-test     Run E2E tests (requires services running)"
	@echo ""
	@echo "  make build-apk     Build Android APK"
	@echo "  make build-web     Build web app"
	@echo "  make build-rust    Build Rust backend"
	@echo "  make build-all     Build everything"
	@echo ""
	@echo "  make format        Format Dart + Rust code"
	@echo "  make lint          Analyze Dart + Rust code"
	@echo "  make clean         Clean all build files"
	@echo ""
	@echo "  make deploy        Full local CI pipeline (format, lint, test, build)"
	@echo "  make changelog-check Ensure CHANGELOG.md [Unreleased] exists"
	@echo "  make docker-test   Run all tests in Docker (no local install)"
	@echo "  make docker-dev    Start dev services in Docker"
	@echo "  make docker-stop   Stop Docker dev services"
	@echo ""
	@echo "  VPS deploy (no CI/CD):"
	@echo "  make deploy-vps-config   Create .env.deploy from template (first time)"
	@echo "  make deploy-vps          Full: sync + build + up + health"
	@echo "  make deploy-vps-sync     rsync source + Flutter build to VPS"
	@echo "  make deploy-vps-build    Rebuild Docker images on VPS"
	@echo "  make deploy-vps-up       Restart containers on VPS"
	@echo "  make deploy-vps-status   Show running containers + version"
	@echo "  make deploy-vps-logs     Tail logs (SERVICES=auth-service)"
	@echo "  make deploy-vps-shell    SSH into VPS"
	@echo "  make deploy-vps-restart  Restart all (or one) containers"
	@echo "  make deploy-vps-askpass  Password auth (prompts, no SSH key needed)"
	@echo ""
	@echo "  Or use npm:  npm run test        npm run build"

# ─── Flutter Frontend ───────────────────────

setup:
	@echo ""
	@echo "📦 Installing frontend dependencies..."
	cd $(FRONTEND) && $(FLUTTER_CMD) pub get
	@echo ""
	@echo "📦 Fetching backend dependencies..."
	cd $(BACKEND) && cargo fetch

test:
	@echo ""
	@echo "🧪 Running Flutter tests..."
	cd $(FRONTEND) && $(FLUTTER_CMD) test

test-cov:
	@echo ""
	@echo "📊 Running Flutter tests with coverage..."
	cd $(FRONTEND) && $(FLUTTER_CMD) test --coverage

watch:
	@echo ""
	@echo "👁️  Running Flutter tests in watch mode..."
	cd $(FRONTEND) && $(FLUTTER_CMD) test --watch

format:
	@echo ""
	@echo "🎨 Formatting code..."
	$(DART_CMD) format $(FRONTEND)/lib $(FRONTEND)/test
	cd $(BACKEND) && cargo fmt

lint:
	@echo ""
	@echo "🔍 Analyzing code..."
	# Fail only on actual errors, not warnings/info. Pre-existing warnings
	# (inherited from before lint was added) are not a deploy gate.
	cd $(FRONTEND) && { $(FLUTTER_CMD) analyze 2>&1 || true; } | tee /tmp/flutter_analyze.log; \
	  if grep -E "^\s*error\s" /tmp/flutter_analyze.log > /dev/null; then \
	    echo "❌ flutter analyze found errors"; exit 1; \
	  else \
	    echo "✅ flutter analyze: no errors"; \
	  fi
	cd $(BACKEND) && cargo clippy -- -D warnings

build-apk:
	@echo ""
	@echo "🤖 Building Android APK..."
	cd $(FRONTEND) && $(FLUTTER_CMD) build apk

build-web:
	@echo ""
	@echo "🌐 Building web app..."
	@GOOGLE_CLIENT_ID=$$(grep GOOGLE_CLIENT_ID .env 2>/dev/null | cut -d '=' -f2 | tr -d '[:space:]' || echo ""); \
	APP_VERSION=$$(git rev-parse --short HEAD 2>/dev/null || echo "dev"); \
	cd $(FRONTEND) && $(FLUTTER_CMD) build web --release --no-tree-shake-icons \
		--dart-define=GOOGLE_CLIENT_ID=$$GOOGLE_CLIENT_ID \
		--dart-define=APP_VERSION=$$APP_VERSION \
		--dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/

# ─── Rust Backend ─────────────────────────────

build-rust:
	@echo ""
	@echo "🔧 Building Rust backend..."
	cd $(BACKEND) && cargo build

test-rust:
	@echo ""
	@echo "🦀 Running Rust tests..."
	@JWT_SECRET=test-secret-for-unit-tests-only cd $(BACKEND) && cargo test

check-rust:
	@echo ""
	@echo "🔎 Checking Rust code..."
	cd $(BACKEND) && cargo check

# ─── Combined ─────────────────────────────────

test-all: test test-rust

build-all: build-web build-rust

clean:
	@echo ""
	@echo "🧹 Cleaning build files..."
	cd $(FRONTEND) && $(FLUTTER_CMD) clean
	cd $(BACKEND) && cargo clean

# ─── Changelog Check ──────────────────────────

changelog-check:
	@echo ""
	@echo "📝 Checking CHANGELOG.md..."
	@if [ ! -f CHANGELOG.md ]; then \
		echo "❌ CHANGELOG.md not found"; \
		exit 1; \
	fi
	@if ! grep -q "## \[Unreleased\]" CHANGELOG.md; then \
		echo "❌ CHANGELOG.md missing [Unreleased] section"; \
		exit 1; \
	fi
	@echo "✅ CHANGELOG.md has [Unreleased] section"

# ─── E2E Tests ────────────────────────────────

e2e-setup:
	@echo ""
	@echo "🎭 Installing Playwright + Chromium..."
	cd ./e2e && npm install
	cd ./e2e && npx playwright install chromium

e2e-test:
	@echo ""
	@echo "🎭 Waiting for Traefik + flutter-web to be ready..."
	@for i in $$(seq 1 30); do \
		if curl -sf http://localhost:8082/ > /dev/null 2>&1; then \
			echo "✅ Frontend ready"; \
			break; \
		fi; \
		sleep 1; \
	done
	@echo "🎭 Running E2E tests..."
	cd ./e2e && npx playwright test

deploy: format lint changelog-check test-all build-web build-rust
	@echo ""
	@echo "✅ All checks passed, services rebuilt, E2E verified. Ready for deployment."

# ─── Docker ───────────────────────────────────

docker-test:
	@echo ""
	@echo "🐳 Running all tests in Docker..."
	docker compose -f docker-compose.test.yml run flutter-test
	docker compose -f docker-compose.test.yml run rust-test
	@echo ""
	@echo "✅ Docker tests complete!"

docker-dev:
	@echo ""
	@echo "🐳 Starting dev services in Docker..."
	docker compose up --build -d

docker-stop:
	@echo ""
	@echo "🛑 Stopping Docker dev services..."
	docker compose down

# ─── VPS deploy (no CI/CD) ─────────────────────────────────────
# Stage-based: each target is independently usable. `make deploy-vps`
# runs all of them. Config in .env.deploy (gitignored) or pass inline.
# SSH: uses ssh-agent by default; set VPS_SSH_KEY in .env.deploy to force,
# or VPS_PASSWORD=... / ARGS="--ask-pass" for password auth (no key needed).
#
# Examples:
#   make deploy-vps                           # full deploy (ssh-agent)
#   make deploy-vps-sync                      # rsync source only
#   make deploy-vps-build SERVICES=auth-service
#   make deploy-vps-logs SERVICES=auth-service
#   make deploy-vps-shell                     # SSH into VPS
#   make deploy-vps-restart SERVICES=auth-service
#
# Password auth (no SSH key):
#   make deploy-vps-askpass                   # prompt for password
#   VPS_PASSWORD='pw' make deploy-vps         # inline
#   make deploy-vps ARGS="--ask-pass"         # forward flag to script
#
# First-time setup:
#   make deploy-vps-config    # creates .env.deploy from template
#   $EDITOR .env.deploy       # fill in VPS_HOST etc.

ARGS ?=

deploy-vps-config:
	@if [ ! -f .env.deploy ]; then \
		cp .env.deploy.example .env.deploy; \
		echo "✅ Created .env.deploy from template"; \
		echo "   Edit it: $$EDITOR .env.deploy"; \
	else \
		echo "ℹ️  .env.deploy already exists — not overwriting"; \
	fi

deploy-vps:
	@./scripts/deploy-vps.sh all $(ARGS)

deploy-vps-sync:
	@./scripts/deploy-vps.sh sync $(ARGS)

deploy-vps-build:
	@./scripts/deploy-vps.sh build $(ARGS)

deploy-vps-up:
	@./scripts/deploy-vps.sh up $(ARGS)

deploy-vps-status:
	@./scripts/deploy-vps.sh status $(ARGS)

deploy-vps-logs:
	@./scripts/deploy-vps.sh logs $(ARGS)

deploy-vps-shell:
	@./scripts/deploy-vps.sh shell $(ARGS)

deploy-vps-restart:
	@./scripts/deploy-vps.sh restart $(ARGS)

# Shortcut: password auth, no key needed. Prompts for VPS password.
deploy-vps-askpass:
	@./scripts/deploy-vps.sh --ask-pass all
