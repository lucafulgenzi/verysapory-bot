FROM ruby:2.6

WORKDIR /app
COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

CMD ["./bot.rb" ]
