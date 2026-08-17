# Marketing Site

A static landing/marketing site built with Astro and served by nginx inside the Docker stack. It explains the product and links to the Flutter app.

## Files

- `math-app/marketing-site/`
- `math-app/docker-compose.yml` (`marketing-site` service)

## Tech Stack

- Astro
- Tailwind CSS
- TypeScript

## Deployment

- The site is built to `marketing-site/dist/`.
- nginx serves `dist/` at the root path (`Host(`localhost`)`, priority 10).
- In production, `sekklings.com` is routed to the marketing site by Traefik.

## Integration

- CTA buttons link to `/app` or `/login` to start the Flutter app.
