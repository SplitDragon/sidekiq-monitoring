#!/bin/bash

# docker build . -t asia.gcr.io/splitdragon/sidekiq-mon:2.1
docker build . -t asia.gcr.io/sd-cicd/sidekiq-mon:latest
docker push asia.gcr.io/sd-cicd/sidekiq-mon:latest