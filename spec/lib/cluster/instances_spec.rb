describe Cluster::Instances do
  include ClientStubHelpers

  ['stop', 'start'].each do |action|
    context ".#{action}_all" do
      it "uses the opsworks client to #{action} the stack" do
        stack_id = 'a stack id'
        stack_double = double('A stack')
        allow(stack_double).to receive(:stack_id).and_return(stack_id)
        allow(Cluster::Stack).to receive(:find_or_create).and_return(stack_double)
        opsworks_client = stub_opsworks_client
        allow(opsworks_client).to receive("#{action}_stack")

        described_class.send("#{action}_all".to_sym)

        expect(opsworks_client).to have_received("#{action}_stack".to_sym).with(stack_id: stack_id)
      end
    end
  end

end
