FRONTEND = ./frontend
BACKEND = ./backend
FLUTTER_ROOT = $(CURDIR)/$(FRONTEND)/flutter_sdk

# Use local Flutter SDK if present, otherwise fall back to system flutter
FLUTTER_CMD = $(if $(wildcard $(FLUTTER_ROOT)),$(FLUTTER_ROOT)/bin/flutter,flutter)
DART_CMD    = $(if $(wildcard $(FLUTTER_ROOT)),$(FLUTTER_ROOT)/bin/dart,dart)

.PHONY: help setup test test-cov watch format lint build-apk build-web build-rust test-rust check-rust test-all clean deploy docker-test docker-dev

help:
	@echo "Math App - Local Development"
	@echo "=============================="
	@echo "  make help          Show this message"
	@echo ""
	@echo "  make setup         Install all dependencies"
	@echo "  make test          Run Flutter tests only"
	@echo "  make test-rust     Run Rust tests only"
	@echo "  make test-all      Run ALL tests (Flutter + Rust)"
	@echo "  make test-cov      Run Flutter tests with coverage"
	@echo "  make watch         Watch mode Flutter tests"
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
	@echo "  make deploy        Full CI pipeline (format+lint+test+build)"
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
	cd $(FRONTEND) && $(FLUTTER_CMD) build web

# ─── Rust Backend ─────────────────────────────

build-rust:
	@echo ""
	@echo "🔧 Building Rust backend..."
	cd $(BACKEND) && cargo build

test-rust:
	@echo ""
	@echo "🦀 Running Rust tests..."
	cd $(BACKEND) && cargo test

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

deploy: format lint test-all build-web build-rust
	@echo ""
	@echo "✅ All checks passed. Ready for deployment."

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
