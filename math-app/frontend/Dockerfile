FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY . .
RUN flutter pub get

ARG GOOGLE_CLIENT_ID
RUN if [ -n "$GOOGLE_CLIENT_ID" ]; then \
      sed -i "s/\$GOOGLE_CLIENT_ID/$GOOGLE_CLIENT_ID/g" web/index.html; \
    fi
RUN flutter build web --release --no-tree-shake-icons \
    --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID \
    --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/

RUN rm -rf /app/build/web/canvaskit

# Cache-bust main.dart.js by appending build timestamp as query param.
# Cloudflare caches static assets for 1 year; without a versioned URL
# the old JS bundle continues being served after deploy.
RUN BUILD_TS=$(date +%s) && \
    sed -i "s/\"main.dart.js\"/\"main.dart.js?v=${BUILD_TS}\"/g" /app/build/web/flutter_bootstrap.js

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
