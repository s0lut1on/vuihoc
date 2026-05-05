# Contributing to Math App

## Required Workflow — No Exceptions

Every code change must follow this exact sequence. These rules are enforced by the `make deploy` target.

### Rule 1: Update CHANGELOG.md

**Before committing any change**, add an entry to `CHANGELOG.md` under the `[Unreleased]` section following [Keep a Changelog](https://keepachangelog.com/) format:

- **Added** — new features
- **Changed** — modifications to existing behavior
- **Deprecated** — features being phased out
- **Removed** — deleted features
- **Fixed** — bug fixes
- **Security** — vulnerability fixes

Example:
```markdown
### Added
- Question Bank microservice with parametric question generation
- BKT adaptive difficulty engine
```

### Rule 2: Run Full Verification

**After every change**, you must run:

```bash
make deploy
```

This runs — in order — with no skips:
1. `make format` — format code
2. `make lint` — static analysis
3. `make changelog-check` — verify CHANGELOG.md was updated
4. `make test-all` — Flutter + Rust unit tests
5. `make docker-dev` — rebuild and start services
6. `make e2e-test` — browser automation tests
7. `make build-web` + `make build-rust` — production builds

If any step fails, fix it before committing.

### Rule 3: Restart Services

**After backend changes**, always run:

```bash
make docker-dev
```

This rebuilds and restarts all microservices so your changes are live.

## Fast Feedback Loop

While developing, you can run individual steps:

```bash
make format lint          # quick syntax/format check
make test                 # Flutter tests only
make test-rust            # Rust tests only
make e2e-test             # E2E tests (requires docker-dev running)
```

But before pushing: **always run `make deploy`**.

## Commit Messages

Follow conventional commits:

```
type(scope): description

[optional body]
```

Types:
- `feat` — new feature
- `fix` — bugfix
- `docs` — documentation only
- `style` — formatting, no logic change
- `refactor` — code restructuring
- `test` — adding/updating tests
- `chore` — build, tooling, deps

Examples:
```
feat(question-bank): add distractor generation engine
fix(home-screen): language switcher not visible on desktop
docs(readme): add e2e testing instructions
test(onboarding): add assessment flow e2e spec
```
