module Cluster
  class CWLogs < Base
    def self.delete
      delete_log_groups
    end

    private

    def self.delete_log_groups
      to_remove = cwlogs_client.describe_log_groups.inject([]){ |memo, page| memo + page.log_groups }.find_all do |lg|
        lg.log_group_name.match(/^#{stack_shortname}_/)
      end

      to_remove.each do |lg|
        cwlogs_client.delete_log_group({log_group_name: lg.log_group_name})
      end
    end
  end
end
