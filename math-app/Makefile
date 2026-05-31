FRONTEND = ./frontend
BACKEND = ./backend
FLUTTER_ROOT = $(CURDIR)/$(FRONTEND)/flutter_sdk

# Use local Flutter SDK if present, otherwise fall back to system flutter
FLUTTER_CMD = $(if $(wildcard $(FLUTTER_ROOT)),$(FLUTTER_ROOT)/bin/flutter,flutter)
DART_CMD    = $(if $(wildcard $(FLUTTER_ROOT)),$(FLUTTER_ROOT)/bin/dart,$(shell dirname $(shell which flutter))/dart)

.PHONY: help setup test test-cov watch format lint changelog-check build-apk build-web build-rust test-rust check-rust test-all clean deploy docker-test docker-dev docker-stop e2e-setup e2e-test

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
	@echo "  make deploy        Full pipeline + docker-dev + e2e"
	@echo "  make changelog-check Ensure CHANGELOG.md [Unreleased] exists"
	@echo "  make docker-test   Run all tests in Docker (no local install)"
	@echo "  make docker-dev    Start dev services in Docker"
	@echo "  make docker-stop   Stop Docker dev services"
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
	cd $(FRONTEND) && $(FLUTTER_CMD) analyze --no-fatal-infos
	cd $(BACKEND) && cargo clippy -- -D warnings

build-apk:
	@echo ""
	@echo "🤖 Building Android APK..."
	cd $(FRONTEND) && $(FLUTTER_CMD) build apk

build-web:
	@echo ""
	@echo "🌐 Building web app..."
	@GOOGLE_CLIENT_ID=$$(grep GOOGLE_CLIENT_ID .env 2>/dev/null | cut -d '=' -f2 | tr -d '[:space:]' || echo ""); \
	cd $(FRONTEND) && $(FLUTTER_CMD) build web --dart-define=GOOGLE_CLIENT_ID=$$GOOGLE_CLIENT_ID

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

deploy: format lint changelog-check test-all build-web build-rust docker-dev e2e-test
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
