FROM ghcr.io/cirruslabs/flutter:3.44.0 AS builder
WORKDIR /app
COPY . .
RUN flutter pub get

ARG GOOGLE_CLIENT_ID
# Default to 'dev' when no APP_VERSION is passed (local builds).
ARG APP_VERSION=dev
RUN if [ -n "$GOOGLE_CLIENT_ID" ]; then \
      sed -i "s/\$GOOGLE_CLIENT_ID/$GOOGLE_CLIENT_ID/g" web/index.html; \
    fi
RUN flutter build web --release \
    --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID \
    --dart-define=APP_VERSION=$APP_VERSION \
    --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/

RUN rm -rf /app/build/web/canvaskit

# Cache-bust main.dart.js and flutter_bootstrap.js by appending build timestamp.
# Cloudflare caches static assets for 1 year; without a versioned URL
# the old JS bundle continues being served after deploy.
#
# Match flutter_bootstrap.js only when NOT followed by '?' — prevents the
# double ?v= bug where the source file already has ?v=1782749966 baked in
# from a previous edit, and the sed would produce
# 'flutter_bootstrap.js?v=1782749966?v=<NEW>' which the browser treats as
# a different URL (causing the bootstrap to be fetched twice).
RUN BUILD_TS=$(date +%s) && \
    sed -i "s/\"main.dart.js\"/\"main.dart.js?v=${BUILD_TS}\"/g" /app/build/web/flutter_bootstrap.js && \
    sed -i "s/flutter_bootstrap\.js\([^?]\)/flutter_bootstrap.js?v=${BUILD_TS}\1/g" /app/build/web/index.html

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
