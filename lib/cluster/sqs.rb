module Cluster
  class SQS < Base
    def self.delete_queue(queue_name)
      sqs_client.list_queues.inject([]){ |memo, page| memo + page.queue_urls }.find_all do |url|
        if url.end_with?(queue_name)
          sqs_client.delete_queue({ queue_url: url })
        end
      end
    end
  end
end
