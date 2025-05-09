FROM ruby:3.4.3

RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
