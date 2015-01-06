
require "vagrant/util/platform"
require "vagrant/util/powershell"
require "json"

# implements:
# https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/plugin/v2/synced_folder.rb

module VagrantPlugins
  module VMM
    class SyncedFolder < Vagrant.plugin("2", :synced_folder)
      #
      def usable?(machine, raise_error=false)
        return false if machine.provider_name != :vmm

        if !Vagrant::Util::Platform.windows?
          raise Errors::WindowsRequired
          return false
        end

        if !Vagrant::Util::PowerShell.available?
          raise Errors::PowerShellRequired
          return false
        end

        true
      end

      # This is called after the machine is booted and after networks
      # are setup.
      #
      # This might be called with new folders while the machine is running.
      # If so, then this should add only those folders without removing
      # any existing ones.
      #
      # No return value.
      def enable(machine, folders, opts)
        machine.ui.output('Syncing folders with the VM via WinRM')

        # generate options
        options = {
          vm_address: machine.provider_config.vm_address,
          folders_to_sync: {},
          winrm_vm_username: machine.config.winrm.username,
          winrm_vm_password: machine.config.winrm.password
        }
        #
        folders.each do |id, data|
          if data[:guestpath]
            # record in options
            options[:folders_to_sync][data[:hostpath]] = data[:guestpath]
          else
            # If no guest path is specified, then automounting is disabled
            machine.ui.detail("No guest path specified for: #{data[:hostpath]}")
          end
        end
        # escape quotes
        options[:folders_to_sync] = options[:folders_to_sync].to_json.gsub('"','\\"')
        res = machine.provider.driver.sync_folders(options)
        machine.ui.detail("Synced finished.")
      end

      # This is called to remove the synced folders from a running
      # machine.
      #
      # This is not guaranteed to be called, but this should be implemented
      # by every synced folder implementation.
      #
      # @param [Machine] machine The machine to modify.
      # @param [Hash] folders The folders to remove. This will not contain
      #   any folders that should remain.
      # @param [Hash] opts Any options for the synced folders.
      def disable(machine, folders, opts)
      end

      # This is called after destroying the machine during a
      # `vagrant destroy` and also prior to syncing folders during
      # a `vagrant up`.
      #
      # No return value.
      #
      # @param [Machine] machine
      # @param [Hash] opts
      def cleanup(machine, opts)
      end

    end
  end
end
