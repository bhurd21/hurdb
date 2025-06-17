Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    allowed_origins = [
      'https://www.immaculategrid.com'
    ]

    origins(*allowed_origins)

    resource '/api/imgrid',
      headers: :any,
      methods: :get
  end
end
