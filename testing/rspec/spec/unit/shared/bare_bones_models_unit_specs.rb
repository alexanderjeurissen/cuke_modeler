require "#{File.dirname(__FILE__)}/../../spec_helper"

shared_examples_for 'a bare bones model' do

  # clazz must be defined by the calling file

  let(:model) { clazz.new }


  it 'can be initialized empty' do
    expect { clazz.new }.to_not raise_error
  end

end
