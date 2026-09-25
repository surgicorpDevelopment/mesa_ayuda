# Multi-stage lento: Flutter compila DENTRO de Docker.
# Preferir Dockerfile.nginx + flutter en el host (ver deploy/update-frontend.ps1).
FROM ghcr.io/cirruslabs/flutter:3.29.2 AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get
COPY . .
RUN flutter build web --release --base-href /app_mesaayuda/ --no-tree-shake-icons

FROM nginx:1.27-alpine
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
