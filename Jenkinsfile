#!/usr/bin/env groovy

REPOSITORY = 'govuk_need_api'
DEFAULT_SCHEMA_BRANCH = 'deployed-to-production'

node('mongodb-2.4') {
  def govuk = load '/var/lib/jenkins/groovy_scripts/govuk_jenkinslib.groovy'

  properties([
    buildDiscarder(
      logRotator(
        numToKeepStr: '50')
      ),
    [$class: 'RebuildSettings', autoRebuild: false, rebuildDisabled: false],
  ])

  try {
    stage("Checkout") {
      checkout scm
    }

    stage("Clean up workspace") {
      govuk.cleanupGit()
    }

    stage("git merge") {
      govuk.mergeMasterBranch()
    }

    stage("Configure Rails environment") {
      govuk.setEnvar("RAILS_ENV", "test")
      govuk.setEnvar("ELASTICSEARCH_HOSTS", "localhost:9200")
      govuk.setEnvar("REDIS_HOST", "127.0.0.1")
    }

    stage("Bundle install") {
      govuk.bundleApp()
    }

    stage("Rubylinter") {
      govuk.rubyLinter("app test lib config")
    }

    stage("Set up the DB") {
      govuk.runRakeTask("db:mongoid:drop")
    }

    stage("Run tests") {
      govuk.runRakeTask("test")
    }

    stage("Push release tag") {
      govuk.pushTag(REPOSITORY, env.BRANCH_NAME, 'release_' + env.BUILD_NUMBER)
    }

    stage("Deploy to integration") {
      govuk.deployIntegration(REPOSITORY, env.BRANCH_NAME, 'release', 'deploy')
    }

  } catch (e) {
    currentBuild.result = "FAILED"
    step([$class: 'Mailer',
          notifyEveryUnstableBuild: true,
          recipients: 'govuk-ci-notifications@digital.cabinet-office.gov.uk',
          sendToIndividuals: true])
    throw e
  }
}
