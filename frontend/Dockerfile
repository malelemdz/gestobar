# Stage 1 - Build Frontend
FROM debian:bookworm-slim AS build-env

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone Flutter stable SDK
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Fetch flutter sdk artifacts
RUN flutter doctor -v

# Set project directory
WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source and build
COPY . .
RUN flutter build web --release

# Stage 2 - Serve static assets with Nginx
FROM nginx:alpine
COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
