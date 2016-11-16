#!/bin/bash -xe

export RAILS_ENV=test

git clean -fdx

bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment

if [[ ${GIT_BRANCH} != "origin/master" ]]; then
  bundle exec govuk-lint-ruby \
    --rails \
    --display-cop-names \
    --display-style-guide \
    --diff \
    --cached \
    --format html --out rubocop-${GIT_COMMIT}.html \
    --format clang \
    app test lib config
fi

export ELASTICSEARCH_HOSTS="localhost:9200"
export REDIS_HOST="127.0.0.1"

bundle exec rake db:mongoid:drop
bundle exec rake test
