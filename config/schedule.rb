set :output, { error: 'log/cron.error.log', standard: 'log/cron.log' }
job_type :rake, 'cd :path && /usr/local/bin/govuk_setenv need-api bundle exec rake :task :output'
job_type :run_script, 'cd :path && RAILS_ENV=:environment /usr/local/bin/govuk_setenv need-api script/:task :output'

every :hour do
  rake "organisations:import"
end
