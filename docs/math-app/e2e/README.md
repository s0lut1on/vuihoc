# E2E Tests for Math App

End-to-end tests using [Playwright](https://playwright.dev/) for the Flutter web frontend and Rust backend.

## Setup

```bash
cd e2e
npm install
npx playwright install chromium
```

Or use the root Makefile:

```bash
make e2e-setup
```

## Run tests

```bash
# Headless (default) — services must already be running (make docker-dev)
make e2e-test

# With browser UI
npx playwright test --headed

# Debug mode
npx playwright test --debug

# Against a specific URL
PLAYWRIGHT_BASE_URL=http://my-server:8082 npx playwright test
```

## Important: Expected Warnings

During `make deploy`, you will see messages in the console that look like errors but are **harmless warnings**:

```
The "ANTHROPIC_API_KEY" variable is not set. Defaulting to a blank string.
The "JWT_SECRET" variable is not set. Defaulting to a blank string.
Docker Compose is configured to build using Bake, but buildx isn't installed
```

These come from Docker Compose and Traefik. They do **not** cause test failures. The E2E tests check only:
- HTTP response status codes
- Page title presence
- JSON response structures

## Test structure

| File | What it tests |
|---|---|
| `tests/smoke.spec.ts` | All 7 backend services return 200 OK + welcome page loads with title |
| `tests/api.spec.ts` | Content API (curriculum, subjects, lessons) + Question Bank mastery endpoint |
| `tests/navigation.spec.ts` | Mobile/desktop screenshots, deep link routing, 404 redirect, page title |
| `tests/onboarding.spec.ts` | Page loads for welcome, home, lesson, celebration, parent-dashboard, pin-gate |

## Config

`playwright.config.ts` does **not** auto-start Docker services. You must run `make docker-dev` first.

To run against a deployed URL instead of localhost:
```bash
PLAYWRIGHT_BASE_URL=http://my-server:8082 make e2e-test
```
