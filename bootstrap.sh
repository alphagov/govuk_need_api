#!/bin/sh

bundle
bundle exec rake db:seed
GOVUK_APP_DOMAIN=production.alphagov.co.uk bundle exec rake organisations:import
bundle exec rake search:reset
