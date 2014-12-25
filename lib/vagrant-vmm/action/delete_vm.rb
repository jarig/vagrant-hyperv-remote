module VagrantPlugins
  module VMM
    module Action
      class DeleteVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          vmm_server_address = env[:machine].provider_config.vmm_server_address
          # generate options
          options = {
            vmm_server_address: vmm_server_address,
            proxy_server_address: env[:machine].provider_config.proxy_server_address
          }

          env[:ui].info("Deleting the machine...")
          env[:machine].provider.driver.delete_vm(options)
          env[:machine].provider.reset_state
          env[:ui].info("Machine removed.")

          @app.call(env)
        end
      end
    end
  end
end
