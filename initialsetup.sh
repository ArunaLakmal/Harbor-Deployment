#!/bin/bash

mkdir -p ~/.ssh/
chmod 700 ~/.ssh
echo "$IRONMANSSH" | base64 -di > ~/.ssh/ironman
chmod 700 ~/.ssh/ironman
echo "$IRONMANPUBSSH" | base64 -di > ~/.ssh/ironman.pub
chmod 700 ~/.ssh/ironman.pub
eval $(ssh-agent -s)
ssh-add ~/.ssh/ironman
