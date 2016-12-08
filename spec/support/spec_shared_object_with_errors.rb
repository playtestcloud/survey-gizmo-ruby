shared_examples_for 'an object with errors' do
  before(:each) do
    stub_request(:any, /#{@base}/).to_return(json_response(false, 'There was an error!'))
    @resource_client = SurveyGizmo::ResourceClient.new(
      @client,
      described_class
    )
  end

  context 'class methods' do
    it 'should raise errors' do
      expect { @resource_client.first(get_attributes) }.to raise_error
      expect { @resource_client.all(get_attributes.merge(page: 1)).to_a }.to raise_error
    end
  end
end
