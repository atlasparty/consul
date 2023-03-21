module Consul
  class Application < Rails::Application
    config.active_storage.service = :digitalocean
  end
end
