#!/bin/sh -e

echo "Bundle start"
bundle --quiet
echo "Bundle complete"

bundle exec rake db:setup
echo "Database setup complete"

GOVUK_APP_DOMAIN=production.alphagov.co.uk bundle exec rake organisations:import

bundle exec rake search:reset
