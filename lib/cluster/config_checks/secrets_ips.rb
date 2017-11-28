module Cluster
  module ConfigChecks
    class VpnCaIpsNotConfigured < StandardError; end

    class VpnCaIpsConfigured < Base
      def self.sane?
        if stack_secrets.fetch(:vpn_ips, []).empty?
          raise VpnCaIpsNotConfigured.new('You must set at least the VPN IP ranges in your secrets.json (capture agent IPs are optional).')
        end
      end
    end
  end
end

Cluster::Config.append_to_check_registry(Cluster::ConfigChecks::VpnCaIpsConfigured)
