#!/bin/bash

docker build . -t asia.gcr.io/splitdragon/sidekiq-mon:latest
docker push asia.gcr.io/splitdragon/sidekiq-mon:latest