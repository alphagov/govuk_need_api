#!/usr/bin/env groovy

node {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'
  govuk.buildProject([
    beforeTest: { ->
      govuk.setEnvar("ELASTICSEARCH_HOSTS", "localhost:9200")
      govuk.setEnvar("REDIS_HOST", "127.0.0.1")
    }
  ])
}
