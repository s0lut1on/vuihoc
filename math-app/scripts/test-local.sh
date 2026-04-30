#!/bin/bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ️  $1${NC}"; }

# Parse arguments
SKIP_BACKEND=false
SKIP_FRONTEND=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-backend) SKIP_BACKEND=true; shift;;
    --skip-frontend) SKIP_FRONTEND=true; shift;;
    *) print_error "Unknown option: $1"; exit 1;;
  esac
done

# Check dependencies
print_info "Checking dependencies..."

check_dependency() {
  if command -v "$1" &> /dev/null; then
    print_success "Found: $1"
    return 0
  else
    print_error "Missing: $1"
    return 1
  fi
}

ALL_DEPS_FOUND=true

if [ "$SKIP_FRONTEND" = false ]; then
  check_dependency flutter || ALL_DEPS_FOUND=false
fi

if [ "$SKIP_BACKEND" = false ]; then
  check_dependency cargo || ALL_DEPS_FOUND=false
fi

if [ "$SKIP_FRONTEND" = false ] && [ "$SKIP_BACKEND" = false ]; then
  check_dependency make || ALL_DEPS_FOUND=false
  check_dependency docker || ALL_DEPS_FOUND=false
fi

if [ "$ALL_DEPS_FOUND" = false ]; then
  echo ""
  print_error "Some dependencies are missing. Install them:"
  echo ""
  echo "  Flutter:  https://docs.flutter.dev/get-started/install"
  echo "  Rust:     https://rustup.rs"
  echo "  Docker:   https://docs.docker.com/get-docker"
  echo ""
  echo "Or run without installing anything:"
  echo "  npm run docker:test"
  echo ""
  exit 1
fi

# Run tests
TOTAL_ERRORS=0

if [ "$SKIP_FRONTEND" = false ]; then
  print_info ""
  print_info "🧪 Running Flutter tests..."
  if cd frontend && flutter test; then
    print_success "Flutter tests passed"
  else
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    print_error "Flutter tests FAILED"
  fi
  cd ..
fi

if [ "$SKIP_BACKEND" = false ]; then
  print_info ""
  print_info "🦀 Running Rust tests..."
  if cd backend && cargo test; then
    print_success "Rust tests passed"
  else
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    print_error "Rust tests FAILED"
  fi
  cd ..
fi

# Final summary
echo ""
if [ $TOTAL_ERRORS -eq 0 ]; then
  print_success "All tests passed!"
  exit 0
else
  print_error "$TOTAL_ERRORS test suite(s) failed."
  exit 1
fi
