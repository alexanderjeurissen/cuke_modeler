require 'spec_helper'

SimpleCov.command_name('Outline') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Outline, Unit' do

  let(:clazz) { CukeModeler::Outline }
  let(:outline) { clazz.new }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element'
    it_should_behave_like 'a named element'
    it_should_behave_like 'a described element'
    it_should_behave_like 'a stepped element'
    it_should_behave_like 'a tagged element'
    it_should_behave_like 'a sourced element'
    it_should_behave_like 'a raw element'

  end


  describe 'unique behavior' do

    it 'can be parsed from stand alone text' do
      source = "Scenario Outline: test outline
              Examples:
                |param|
                |value|"

      expect { @element = clazz.new(source) }.to_not raise_error

      # Sanity check in case instantiation failed in a non-explosive manner
      @element.name.should == 'test outline'
    end

    it 'can be instantiated with the minimum viable Gherkin', :gherkin4 => true do
      source = "Scenario Outline:"

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'can be instantiated with the minimum viable Gherkin', :gherkin2 => true do
      source = "Scenario Outline:"

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad outline text \n Scenario Outline:\n And a step\n @foo "

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_outline\.feature'/)
    end

    it 'trims whitespace from its source description' do
      source = ['Scenario Outline:',
                '  ',
                '        description line 1',
                '',
                '   description line 2',
                '     description line 3               ',
                '',
                '',
                '',
                '  * a step',
                '',
                'Examples:',
                '|param|',
                '|value|']
      source = source.join("\n")

      outline = clazz.new(source)
      description = outline.description.split("\n")

      expect(description).to eq(['     description line 1',
                                 '',
                                 'description line 2',
                                 '  description line 3'])
    end

    it 'has examples' do
      outline.should respond_to(:examples)
    end

    it 'can change its examples' do
      expect(outline).to respond_to(:examples=)

      outline.examples = :some_examples
      outline.examples.should == :some_examples
      outline.examples = :some_other_examples
      outline.examples.should == :some_other_examples
    end


    describe 'abstract instantiation' do

      context 'a new outline object' do

        let(:outline) { clazz.new }


        it 'starts with no examples' do
          expect(outline.examples).to eq([])
        end

      end

    end

    it 'contains steps, examples, and tags' do
      tags = [:tag_1, :tagt_2]
      steps = [:step_1, :step_2, :step_3]
      examples = [:example_1, :example_2, :example_3]
      everything = steps + examples + tags

      outline.steps = steps
      outline.examples = examples
      outline.tags = tags

      expect(outline.children).to match_array(everything)
    end


    describe 'model population' do

      context 'from source text' do

        # gherkin 3.x does not accept incomplete outlines
        context 'a filled outline', :gherkin3 => false do

          let(:source_text) { 'Scenario Outline: Outline name

                                 Scenario description.

                               Some more.
                                   Even more.' }
          let(:outline) { clazz.new(source_text) }


          it "models the outline's name" do
            expect(outline.name).to eq('Outline name')
          end

          # gherkin 3.x does not accept incomplete outlines
          it "models the outline's description", :gherkin3 => false do
            description = outline.description.split("\n")

            expect(description).to eq(['  Scenario description.',
                                       '',
                                       'Some more.',
                                       '    Even more.'])
          end

        end

        # gherkin 3.x does not accept incomplete outlines
        context 'an empty outline', :gherkin3 => false do

          let(:source_text) { 'Scenario Outline:' }
          let(:outline) { clazz.new(source_text) }

          it "models the outline's name" do
            expect(outline.name).to eq('')
          end

          it "models the outline's description" do
            expect(outline.description).to eq('')
          end

        end

      end

    end


    describe 'comparison' do

      it 'can gracefully be compared to other types of objects' do
        # Some common types of object
        [1, 'foo', :bar, [], {}].each do |thing|
          expect { outline == thing }.to_not raise_error
          expect(outline == thing).to be false
        end
      end

    end


    describe 'outline output' do

      it 'is a String' do
        outline.to_s.should be_a(String)
      end


      context 'from source text' do

        # gherkin 3.x does not accept incomplete outlines
        it 'can output an empty outline', :gherkin3 => false do
          source = ['Scenario Outline:']
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n")

          expect(outline_output).to eq(['Scenario Outline:'])
        end

        # gherkin 3.x does not accept incomplete outlines
        it 'can output a outline that has a name', :gherkin3 => false do
          source = ['Scenario Outline: test outline']
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n")

          expect(outline_output).to eq(['Scenario Outline: test outline'])
        end

        # gherkin 3.x does not accept incomplete outlines
        it 'can output a outline that has a description', :gherkin3 => false do
          source = ['Scenario Outline:',
                    'Some description.',
                    'Some more description.']
          source = source.join("\n")
          outline = clazz.new(source)

          outline_output = outline.to_s.split("\n")

          expect(outline_output).to eq(['Scenario Outline:',
                                        '',
                                        'Some description.',
                                        'Some more description.'])
        end

      end


      context 'from abstract instantiation' do

        let(:outline) { clazz.new }


        it 'can output an empty outline' do
          expect { outline.to_s }.to_not raise_error
        end

        it 'can output an outline that has only a name' do
          outline.name = 'a name'

          expect { outline.to_s }.to_not raise_error
        end

        it 'can output an outline that has only a description' do
          outline.description = 'a description'

          expect { outline.to_s }.to_not raise_error
        end

      end

    end

  end

end
