web: bundle exec puma -C config/puma.rb
worker: /usr/bin/env LIBRATO_AUTORUN=1 bundle exec sidekiq -c 1
release: rake db:migrate
