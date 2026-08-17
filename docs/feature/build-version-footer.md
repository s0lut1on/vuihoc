# Build Version Footer

A small footer on the home screen shows the deployed git commit SHA. This makes it easy to verify whether the live build matches the expected `main` commit and whether CDN/browser caches are serving stale bundles.

## Files

- `math-app/frontend/lib/core/build_info.dart`
- `math-app/frontend/lib/screens/home_screen.dart` (`_BuildVersionFooter`)
- `math-app/Makefile` (`build-web` target)

## Injection

- `kBuildVersion` is a `String.fromEnvironment('APP_VERSION', defaultValue: 'dev')`.
- `make build-web` injects the short git SHA via `--dart-define=APP_VERSION=$(git rev-parse --short HEAD)`.
- `make deploy-vps` also passes the SHA as `APP_VERSION`.

## UI

- Displays `🐸 HocVui <sha>` at the bottom of `HomeScreen`.
- Style: small pill with muted text and a subtle border.

## Troubleshooting

- Footer says `HocVui dev` → local/debug build, `APP_VERSION` not passed.
- Footer shows old SHA after deploy → hard-refresh browser to clear Cloudflare/cache.
