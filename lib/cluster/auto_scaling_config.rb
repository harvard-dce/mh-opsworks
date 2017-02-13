module Cluster
  class AutoScalingConfig < Base
    def self.set_auto_scaling_params(layer_id, params)
      if params[:instances].has_key?(:scaling)
        scaling_params = params[:instances][:scaling]

        up_scaling = scaling_params.fetch(:up, {})
        down_scaling = scaling_params.fetch(:down, {})
        # This alarm name is tightly coupled to the topic_name
        # and the oc-opsworks-recipes::install-job-queued-metrics recipe
        alarm_suffix = up_scaling.delete(:alarm_suffix)
        up_scaling[:alarms] = [ %Q|#{topic_name}#{alarm_suffix}| ]

        opsworks_client.set_load_based_auto_scaling(
          layer_id: layer_id,
          enable: scaling_params.fetch(:enable, false),
          up_scaling: up_scaling,
          down_scaling: down_scaling
        )
      end
    end
  end
end
