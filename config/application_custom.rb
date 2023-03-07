module Consul
  class Application < Rails::Application
    config.active_storage.service = :s3
  end
end
