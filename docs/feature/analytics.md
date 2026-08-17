# Analytics

The Docker dev stack includes Umami for privacy-friendly web analytics. It is served under the `/umami` path prefix.

## Files

- `math-app/docker-compose.yml` (`umami`, `umami-db` services)

## Services

- `umami` — Umami analytics app (PostgreSQL build).
- `umami-db` — PostgreSQL 15 database for Umami.

## Configuration

- `DATABASE_URL=postgresql://umami:umami@umami-db:5432/umami`
- `APP_SECRET=dev-secret-change-in-prod` (must be changed in production).

## Routing

- Traefik serves Umami at `/umami` with a strip-prefix middleware.
- Static `_next` assets are routed separately.

## Production Note

- Replace `APP_SECRET` with a strong secret.
- Use a dedicated analytics domain or path in production.
