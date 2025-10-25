class DkBaseRecord < ActiveRecord::Base
  self.abstract_class = true
  
  # Establish connection manually when environment variables are present
  if ENV['DB_HOST'].present? && ENV['DB_NAME'].present?
    establish_connection(
      adapter: 'postgresql',
      host: ENV.fetch('DB_HOST'),
      port: ENV.fetch('DB_PORT', 5432),
      database: ENV.fetch('DB_NAME'),
      username: ENV.fetch('DB_USER'),
      password: ENV.fetch('DB_PASSWORD'),
      pool: ENV.fetch('RAILS_MAX_THREADS', 5)
    )
  end
end
