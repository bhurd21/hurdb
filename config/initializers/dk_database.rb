# Configure multiple database connections
Rails.application.configure do
  # Ensure DK database connection is properly established only if environment variables are present
  config.after_initialize do
    if ENV['DB_HOST'].present? && ENV['DB_NAME'].present?
      begin
        DkGame.connection.execute("SELECT 1")
        Rails.logger.info "DK Games PostgreSQL database connection established successfully"
      rescue => e
        Rails.logger.warn "DK Games PostgreSQL database connection failed: #{e.message}"
        Rails.logger.warn "Application will fallback to mock data for betting information"
      end
    else
      Rails.logger.info "DK Games PostgreSQL environment variables not set, using mock data"
    end
  end
end
