module VCAP
  module CloudController
    class AppFactory
      def self.make(attributes={})
        defaults = {
            droplet_hash: Sham.guid,
            package_hash: Sham.guid,
        }
        attributes = defaults.merge(attributes)

        app = VCAP::CloudController::App.make(attributes)
        app.add_new_droplet(app.droplet_hash) if app.droplet_hash

        App.find(id: app.id)
      end
    end

    class ProcessFactory
      def self.make(attributes={})
        defaults = {
            droplet_hash: Sham.guid,
            package_hash: Sham.guid,
        }
        attributes = defaults.merge(attributes)

        app = VCAP::CloudController::ProcessModel.make(attributes)
        app.add_new_droplet(app.droplet_hash) if app.droplet_hash

        ProcessModel.find(id: app.id)
      end
    end
  end
end
