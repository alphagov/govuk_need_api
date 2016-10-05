# GOV.UK Need API

The Need API is a JSON read and write API for information about user needs on GOV.UK. It's a Rails app which is part of the GOV.UK Publishing Platform.

## Dependencies

- Ruby (1.9.3)
- Bundler
- MongoDB (with experimental text search feature enabled)
- Elasticsearch (running on port 9200)
- Redis (running on port 6379)

The Need API is not dependent on any other GOV.UK appliations in order to run.

## Getting started

The bootstrap script should get you up and running. It runs Bundler, sets up a stub user in the database, imports a list of government organisations from GOV.UK and creates the Elasticsearch index.

    ./script/bootstrap
    bundle exec unicorn -p 3000

Once Unicorn is running, visit <http://localhost:3000> for a list of all the endpoints provided by the API.

### GDS development

If you're using the development VM, you should run the app from the `development` repository using Bowler and Foreman.

    cd development/
    bowl need_api

From your host machine, you should be able to access the running app at <http://need-api.dev.gov.uk/>.

## User accounts

Authentication is provided by the [GDS-SSO](https://github.com/alphagov/gds-sso) gem, and in the production environemt an instance of [Signon](https://github.com/alphagov/signonotron2) must be running in order to sign in.

In the development environment, the mock strategy is used by default. This removes the requirement for authentication, instead returning the first user in the database as the current user. For this to work, a user must exist - there's a user defined in `db/seeds.rb` which will be created with the bootstrap script.

## Organisations

Organisations are imported from the [Whitehall](https://github.com/alphagov/whitehall) Organisations API. This import is automated using a Rake task:

    GOVUK_APP_DOMAIN=production.alphagov.co.uk bundle exec rake organisations:import

## Search

The tests (and the search/indexing functionality) won't work unless you have an elasticsearch server running on localhost port 9200, or unless you change the configuration in `config/initializers/elasticsearch.rb`.

To set up the search index (or to clear out an old one and start again), you can run the `search:reset` Rake task, which will replace any existing index and re-index all needs. There are other Rake tasks available if you want to do this piece by piece, or update mappings for an existing index.
