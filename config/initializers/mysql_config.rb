# MySQL External Database Configuration
Rails.application.configure do
  # MySQL connection configuration
  # You can set these via environment variables for better security

  config.mysql_config = {
    host: ENV.fetch('MYSQL_HOST'),
    port: ENV.fetch('MYSQL_PORT'),
    database: ENV.fetch('MYSQL_DATABASE'),
    username: ENV.fetch('MYSQL_USER'),
    password: ENV.fetch('MYSQL_PASSWORD'),
    encoding: 'utf8mb4',
    pool: 5,
    timeout: 5000
  }
end
