# Sidekiq Monitoring

This tool reads sidekiq metrics and outputs:
* Log messages to be read by Cloud Logging. Can create Log Based Metrics with those messages and alert based on those.
* Cloud Monitoring metrics by calling the API directly.


# Installation
* Navigate to `build-push.sh` and update the `VERSION`
* Execute `build-push.sh` to create a container and push it to gcr.io