module Cluster
  class RakeDocs
    def initialize(task_name)
      @task_name = task_name
      @content = File.read(doc_file_path)
    end

    def desc
      @content
    end

    private

    attr_reader :task_name, :content

    def doc_file_path
      %Q|./lib/tasks/docs/#{task_name}.txt|
    end
  end
end
