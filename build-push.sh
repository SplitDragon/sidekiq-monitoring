#!/bin/bash

VERSION=3.2

docker build . -t asia.gcr.io/sd-cicd/sidekiq-mon:${VERSION}
# docker build . -t asia.gcr.io/sd-cicd/sidekiq-mon:latest
docker push asia.gcr.io/sd-cicd/sidekiq-mon:${VERSION}
# docker push asia.gcr.io/sd-cicd/sidekiq-mon:latest
