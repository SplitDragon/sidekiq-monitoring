FROM ruby:2.6.5-alpine

RUN gem install sidekiq

RUN mkdir /app
WORKDIR /app

COPY sidekiq-monitoring.rb .

CMD REDIS_PROVIDER=SIDEKIQ_REDIS_URL ruby sidekiq-monitoring.rb