FROM ruby:3.0.7-slim-buster

# RUN apt update && apt install -y build-essential
RUN gem install sidekiq google-cloud-monitoring

RUN mkdir /app
WORKDIR /app

COPY sidekiq-monitoring.rb .

CMD ruby sidekiq-monitoring.rb