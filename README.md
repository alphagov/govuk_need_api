# GOV.UK Need API

This app exposes information about user needs on GOV.UK.

## Getting started

There are no application dependencies required to get the Need API up and running. Once you've checked out the repo and installed the gem dependencies, you should be ready to go:

    bundle install
    bundle exec unicorn -p 3000

The tests (and the search/indexing functionality) won't work unless you have an elasticsearch server running on localhost port 9200, or unless you change the configuration in `config/initializers/elasticsearch.rb`.

### GDS development

If you're using the development VM, you should run the app from the `development` repository using Bowler and Foreman.

    cd development/
    bowl need_api

From your host machine, you should be able to access the running app at <http://need-api.dev.gov.uk/>.

### Creating the seed user

If you're running the Need API in the development environment when using the [GDS-SSO](https://github.com/alphagov/gds-sso) mock strategy (set by default), you'll need to create a test user in the database. The seed task will do this for you:

    bundle exec rake db:seed
