FROM ruby:2.6.5-alpine

RUN gem install sidekiq

RUN mkdir /app
WORKDIR /app

COPY sidekiq-monitoring.rb .

CMD ruby sidekiq-monitoring.rb