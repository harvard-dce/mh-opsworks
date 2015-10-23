module Cluster
  class SeedFileChooser
    attr_reader :seed_file, :bucket

    def initialize(seed_file: '', bucket: '')
      @seed_file = seed_file
      @bucket = bucket
    end

    def valid_seed_file?
      remote_seed_files.include?(seed_file)
    end

    def remote_seed_files
      Cluster::Assets.list_objects_in(bucket: bucket).sort
    end

    def choose
      puts
      puts "Please choose a seed file by number: (ctrl-c to quit)\n\n"
      remote_seed_files.each_with_index do |config, index|
        puts  %Q|#{index}. #{config}|
      end

      print "\nSeed number: "
      seed_input = STDIN.gets.strip.chomp
      seed_number = seed_input.to_i
      seed_name = remote_seed_files[seed_number]
      if seed_input.match(/^\d+$/) && seed_name
        return seed_name
      end
      puts "\nPlease choose a valid seed.\n"
      choose
    end
  end
end
