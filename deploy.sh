#!/bin/bash

set -e

echo "Building Flutter Web..."
flutter build web --release

echo "Packaging build..."
tar -czf vikoba-web-build.tar.gz \
  --exclude='._*' \
  -C build/web .

echo "Uploading to VPS..."
scp vikoba-web-build.tar.gz root@185.183.55.100:/opt/apps/

echo "Deploying on VPS..."
ssh root@185.183.55.100 << 'EOF'

set -e

cd /opt/apps/vikoba-flutter

# Replace existing web files
find site -mindepth 1 -maxdepth 1 -exec rm -rf {} +

tar -xzf /opt/apps/vikoba-web-build.tar.gz -C site

# Rebuild image
docker build -t vikoba-flutter-web:1.0.0 .

# Restart Flutter container
docker rm -f vikoba-flutter-web

docker run -d \
  --name vikoba-flutter-web \
  --restart unless-stopped \
  -p 127.0.0.1:3001:80 \
  vikoba-flutter-web:1.0.0

echo "Flutter Web deployment completed!"

EOF

rm -f vikoba-web-build.tar.gz

echo "Deployment successful!"
