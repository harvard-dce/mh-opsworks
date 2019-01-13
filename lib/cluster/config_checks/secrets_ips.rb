module Cluster
  module ConfigChecks
    class VpnCaIpsNotConfigured < StandardError; end

    class VpnCaIpsConfigured < Base
      def self.sane?
        if stack_custom_json.fetch(:vpn_ips, []).empty?
          raise VpnCaIpsNotConfigured.new("The VPN IP ranges are missing from your stack's custom_json. These are provided automatically by the `base-secrets.json` for new clusters. For older clusters you can probably get them from your local `secrets.json` file. (Then remove them from `secrets.json`).")
        end
        if stack_secrets[:vpn_ips]
          STDERR.puts "Deprecation notice: VPN and Capture Agent ips are no longer read from `secrets.json` and can be removed.".colorize(:red)
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::VpnCaIpsConfigured)
