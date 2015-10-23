describe Cluster::SeedFileChooser do
  context '#valid_seed_file?' do
    it 'is false when the seed file does not exist remotely' do
      seed_file = 'bloopity.json'
      chooser = described_class.new(seed_file: seed_file)
      allow(chooser).to receive(:remote_seed_files).and_return(['foo.json'])

      expect(chooser.valid_seed_file?).to be false
    end

    it 'is true when the seed file exists remotely' do
      seed_file = 'bloopity.json'
      chooser = described_class.new(seed_file: seed_file)
      allow(chooser).to receive(:remote_seed_files).and_return(['bloopity.json'])

      expect(chooser.valid_seed_file?).to be true
    end

    it 'checks remotely in the correct bucket when validating a seed_file' do
      bucket = 'test_bucket'
      chooser = described_class.new(seed_file: 'seed_file', bucket: bucket)

      allow(Cluster::Assets).to receive(:list_objects_in).and_return([])

      chooser.valid_seed_file?

      expect(Cluster::Assets).to have_received(:list_objects_in).with(bucket: bucket)
    end
  end
end
