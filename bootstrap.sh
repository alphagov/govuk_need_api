#!/bin/sh

bundle
bundle exec rake db:setup
GOVUK_APP_DOMAIN=production.alphagov.co.uk bundle exec rake organisations:import
bundle exec rake search:reset
