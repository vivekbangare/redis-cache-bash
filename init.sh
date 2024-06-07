#!/bin/bash

echo "Build redis with custom password"
docker build -t redis .

echo "Running Redis Server"
docker run -d --name myredis --rm -p 6379:6379 redis
