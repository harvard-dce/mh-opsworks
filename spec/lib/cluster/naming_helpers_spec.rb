describe Cluster::NamingHelpers do

  context '.stack_shortname' do
    [
      'FOOBAR',
      'FOO BAR',
      'asdlfkj293248sdfkj------XXXXX',
      'Bellep 390 %%^#$%$',
      'Foo_test_name'
    ].each do |name|
      it "generates names that match the correct pattern for #{name}" do
        NamingHelperTestClass.stack_name = name
        expect(NamingHelperTestClass.stack_shortname.match(/^[a-zA-Z][-a-zA-Z0-9]*/)).to be
      end
    end
  end

  class NamingHelperTestClass
    include Cluster::NamingHelpers

    def self.stack_name=(name)
      @@stack_name = name
    end

    def self.stack_config
      { name: @@stack_name }
    end
  end
end
