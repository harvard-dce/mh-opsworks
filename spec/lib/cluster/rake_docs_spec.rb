describe Cluster::RakeDocs do
  context '#new' do
    it 'reads a file based on the name we give it' do
      task_name = 'admin:foo'
      allow(File).to receive(:read)
      docs = described_class.new(task_name)

      docs.desc

      expect(File).to have_received(:read).with("./lib/tasks/docs/#{task_name}.txt")
    end
  end

  context '#desc' do
    it 'gets content from the file' do
      allow(File).to receive(:read).and_return('I am awesome content')
      docs = described_class.new('bleep')

      expect(docs.desc).to eq 'I am awesome content'
    end
  end
end
