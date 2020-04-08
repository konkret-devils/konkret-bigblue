#!/bin/bash

INSTANCE_NAME="konkret-main"
CONTAINER_NAME="konkret-bigblue"
RELEASE_NAME="release-v2"
DEPLOY_ROOT_DIR="/opt/grandbleu"

DEPLOY_DIR="$DEPLOY_ROOT_DIR/$INSTANCE_NAME"
INSTANCE_CONFIG_DIR="$DEPLOY_DIR/config/instances/$INSTANCE_NAME"
CURRENT_DIR=$(pwd)

echo ""
echo "*********************************"
echo "* Deploying bigBLUE instance  : * $INSTANCE_NAME to $DEPLOY_DIR - target container: $CONTAINER_NAME:$RELEASE_NAME ..."
echo "*********************************"
cd $DEPLOY_DIR || { echo "DEPLOY_DIR $DEPLOY_DIR does not exist! Exiting." && exit 1; }

echo ""
echo "  1 - Cleaning ..."
rm -r "$DEPLOY_DIR/public/*"
rm "$DEPLOY_DIR/app/assets/stylesheets/utilities/_variables.scss"
git stash

echo "  2 - GIT pull ..."
git pull -a

echo "  3 - Copying from instance config to target locations ..."
cp -r "$INSTANCE_CONFIG_DIR/images/*" "$DEPLOY_DIR/public/"
cp "$INSTANCE_CONFIG_DIR/sass/_variables.scss" "$DEPLOY_DIR/app/assets/stylesheets/utilities/_variables.scss"

echo "  4 - Rebuilding and Relaunching Docker Container ..."
cd $DEPLOY_DIR && docker-compose down && ./scripts/image_build.sh $CONTAINER_NAME $RELEASE_NAME && docker-compose up -d

cd "$CURRENT_DIR" || exit 2

echo ""
echo "..Done."
echo ""
echo "*********************************"

exit 0