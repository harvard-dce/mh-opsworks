module ClientStubHelpers
  def stub_s3_client
    Aws::S3::Client.new(stub_responses: true).tap do |client|
      allow(client).to receive(:wait_until)
      allow(Cluster::Base).to receive(:s3_client).and_return(client)
      yield client if block_given?
    end
  end

  def stub_cloudformation_client
    Aws::CloudFormation::Client.new(stub_responses: true).tap do |client|
      allow(client).to receive(:wait_until)
      allow(Cluster::Base).to receive(:cloudformation_client).and_return(client)
      yield client if block_given?
    end
  end

  def stub_iam_client
    Aws::IAM::Client.new(stub_responses: true).tap do |client|
      allow(client).to receive(:wait_until)
      allow(Cluster::Base).to receive(:iam_client).and_return(client)
      yield client if block_given?
    end
  end

  def stub_opsworks_client
    Aws::OpsWorks::Client.new(stub_responses: true).tap do |client|
      allow(client).to receive(:wait_until)
      allow(Cluster::Base).to receive(:opsworks_client).and_return(client)
      yield client if block_given?
    end
  end

  def stub_ec2_client
    Aws::EC2::Client.new(stub_responses: true).tap do |client|
      allow(client).to receive(:wait_until)
      allow(Cluster::Base).to receive(:ec2_client).and_return(client)
      yield client if block_given?
    end
  end
end
