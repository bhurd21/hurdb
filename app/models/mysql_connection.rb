# MySQL connection class for external database
class MysqlConnection < ActiveRecord::Base
  # This class connects to an external MySQL database
  # while keeping the main app on SQLite
  
  # Establish connection to external MySQL database
  self.abstract_class = true
  
  # Configuration for MySQL connection
  # Uses configuration from config/initializers/mysql_config.rb
  def self.establish_mysql_connection
    config = Rails.application.config.mysql_config
    establish_connection({
      adapter: 'mysql2'
    }.merge(config))
  end
  
  # Call this method to connect to MySQL
  def self.connect_to_mysql
    establish_mysql_connection
  rescue ActiveRecord::ConnectionNotEstablished => e
    Rails.logger.error "Failed to connect to MySQL: #{e.message}"
    nil
  end
  
  # Test the MySQL connection
  def self.test_connection
    connect_to_mysql
    connection.execute("SELECT 1")
    true
  rescue => e
    Rails.logger.error "MySQL connection test failed: #{e.message}"
    false
  end
end
