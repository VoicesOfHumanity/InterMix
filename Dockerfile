FROM ruby:3.2

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

RUN apt-get update && apt-get install -y nodejs mariadb-client vim --no-install-recommends && rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
RUN bundle config --global frozen 1
RUN bundle config set --local without 'development test'
RUN bundle install

COPY . /usr/src/app
RUN bundle exec rake DATABASE_URL=mysql2:does_not_exist assets:precompile

EXPOSE 3000
CMD ['rails', 'server', '-b', '0.0.0.0']