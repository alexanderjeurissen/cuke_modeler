require "#{File.dirname(__FILE__)}/../../spec_helper"


describe 'Background, Integration' do

  let(:clazz) { CukeModeler::Background }
  let(:minimum_viable_gherkin) { "#{BACKGROUND_KEYWORD}:" }
  let(:maximum_viable_gherkin) do
    "#{BACKGROUND_KEYWORD}: test background

     Background
     description

       #{STEP_KEYWORD} a step
         | value1 |
         | value2 |
       #{STEP_KEYWORD} another step
         \"\"\" with content type
         some text
         \"\"\""
  end


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end

  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin' do
      expect { clazz.new(minimum_viable_gherkin) }.to_not raise_error
    end

    it 'can parse text that uses a non-default dialect' do
      original_dialect = CukeModeler::Parsing.dialect
      CukeModeler::Parsing.dialect = 'en-au'

      begin
        source_text = 'First off: Background name'

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.name).to eq('Background name')
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    describe 'parsing data' do

      context 'with minimum viable Gherkin' do

        let(:source_text) { minimum_viable_gherkin }

        it 'stores the original data generated by the parsing adapter', if: gherkin?(13, 14, 15, 16) do
          background = clazz.new(source_text)
          data = background.parsing_data

          expect(data.keys).to match_array([:background])
          expect(data[:background].keys).to match_array([:id, :keyword, :location, :name])
          expect(data[:background][:keyword]).to eq(BACKGROUND_KEYWORD)
        end

        it 'stores the original data generated by the parsing adapter', if: gherkin?(9, 10, 11, 12) do
          background = clazz.new(source_text)
          data = background.parsing_data

          expect(data.keys).to match_array([:background])
          expect(data[:background].keys).to match_array([:keyword, :location, :name])
          expect(data[:background][:keyword]).to eq(BACKGROUND_KEYWORD)
        end

      end

      context 'with maximum viable Gherkin' do

        let(:source_text) { maximum_viable_gherkin }

        it 'stores the original data generated by the parsing adapter', if: gherkin?(13, 14, 15, 16) do
          background = clazz.new(source_text)
          data = background.parsing_data

          expect(data.keys).to match_array([:background])
          expect(data[:background].keys).to match_array([:description, :id, :keyword, :location, :name, :steps])
          expect(data[:background][:name]).to eq('test background')
        end

        it 'stores the original data generated by the parsing adapter', if: gherkin?(9, 10, 11, 12) do
          background = clazz.new(source_text)
          data = background.parsing_data

          expect(data.keys).to match_array([:background])
          expect(data[:background].keys).to match_array([:description, :keyword, :location, :name, :steps])
          expect(data[:background][:name]).to eq('test background')
        end

      end

    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad background text \n #{BACKGROUND_KEYWORD}:\n #{STEP_KEYWORD} a step\n @foo "

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_background\.feature'/)
    end

    it 'properly sets its child models' do
      source = "#{BACKGROUND_KEYWORD}: Test background
                  #{STEP_KEYWORD} a step"

      background = clazz.new(source)
      step = background.steps.first

      expect(step.parent_model).to equal(background)
    end

    it 'trims whitespace from its source description' do
      source = ["#{BACKGROUND_KEYWORD}:",
                '  ',
                '        description line 1',
                '',
                '   description line 2',
                '     description line 3               ',
                '',
                '',
                '',
                "  #{STEP_KEYWORD} a step"]
      source = source.join("\n")

      background = clazz.new(source)
      description = background.description.split("\n", -1)

      expect(description).to eq(['     description line 1',
                                 '',
                                 'description line 2',
                                 '  description line 3'])
    end


    describe 'getting ancestors' do

      before(:each) do
        CukeModeler::FileHelper.create_feature_file(text: source_gherkin,
                                                    name: 'background_test_file',
                                                    directory: test_directory)
      end


      let(:test_directory) { CukeModeler::FileHelper.create_directory }
      let(:source_gherkin) {
        "#{FEATURE_KEYWORD}: Test feature

           #{BACKGROUND_KEYWORD}: Test background
             #{STEP_KEYWORD} a step"
      }

      let(:directory_model) { CukeModeler::Directory.new(test_directory) }
      let(:background_model) { directory_model.feature_files.first.feature.background }


      it 'can get its directory' do
        ancestor = background_model.get_ancestor(:directory)

        expect(ancestor).to equal(directory_model)
      end

      it 'can get its feature file' do
        ancestor = background_model.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory_model.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = background_model.get_ancestor(:feature)

        expect(ancestor).to equal(directory_model.feature_files.first.feature)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = background_model.get_ancestor(:example)

        expect(ancestor).to be_nil
      end

    end


    describe 'model population' do

      context 'from source text' do

        let(:source_text) { "#{BACKGROUND_KEYWORD}:" }
        let(:background) { clazz.new(source_text) }


        it "models the background's keyword" do
          expect(background.keyword).to eq(BACKGROUND_KEYWORD)
        end

        it "models the background's source line" do
          source_text = "#{FEATURE_KEYWORD}:

                           #{BACKGROUND_KEYWORD}: foo
                             #{STEP_KEYWORD} step"
          background = CukeModeler::Feature.new(source_text).background

          expect(background.source_line).to eq(3)
        end

        context 'a filled background' do

          let(:source_text) {
            "#{BACKGROUND_KEYWORD}: Background name

              Background description.

            Some more.
                Even more.

                #{STEP_KEYWORD} a step
                #{STEP_KEYWORD} another step"
          }
          let(:background) { clazz.new(source_text) }


          it "models the background's name" do
            expect(background.name).to eq('Background name')
          end

          it "models the background's description" do
            description = background.description.split("\n", -1)

            expect(description).to eq(['  Background description.',
                                       '',
                                       'Some more.',
                                       '    Even more.'])
          end

          it "models the background's steps" do
            step_names = background.steps.map(&:text)

            expect(step_names).to eq(['a step', 'another step'])
          end

        end

        context 'an empty background' do

          let(:source_text) { "#{BACKGROUND_KEYWORD}:" }
          let(:background) { clazz.new(source_text) }


          it "models the background's name" do
            expect(background.name).to eq('')
          end

          it "models the background's description" do
            expect(background.description).to eq('')
          end

          it "models the background's steps" do
            expect(background.steps).to eq([])
          end

        end

      end

    end


    describe 'comparison' do

      it 'is equal to a background with the same steps' do
        source = "#{BACKGROUND_KEYWORD}:
                    #{STEP_KEYWORD} step 1
                    #{STEP_KEYWORD} step 2"
        background_1 = clazz.new(source)

        source = "#{BACKGROUND_KEYWORD}:
                    #{STEP_KEYWORD} step 1
                    #{STEP_KEYWORD} step 2"
        background_2 = clazz.new(source)

        source = "#{BACKGROUND_KEYWORD}:
                    #{STEP_KEYWORD} step 2
                    #{STEP_KEYWORD} step 1"
        background_3 = clazz.new(source)


        expect(background_1).to eq(background_2)
        expect(background_1).to_not eq(background_3)
      end

      it 'is equal to a scenario with the same steps' do
        source = "#{BACKGROUND_KEYWORD}:
                    #{STEP_KEYWORD} step 1
                    #{STEP_KEYWORD} step 2"
        background = clazz.new(source)

        source = "#{SCENARIO_KEYWORD}:
                    #{STEP_KEYWORD} step 1
                    #{STEP_KEYWORD} step 2"
        scenario_1 = CukeModeler::Scenario.new(source)

        source = "#{SCENARIO_KEYWORD}:
                    #{STEP_KEYWORD} step 2
                    #{STEP_KEYWORD} step 1"
        scenario_2 = CukeModeler::Scenario.new(source)


        expect(background).to eq(scenario_1)
        expect(background).to_not eq(scenario_2)
      end

      it 'is equal to an outline with the same steps' do
        source = "#{BACKGROUND_KEYWORD}:
                    #{STEP_KEYWORD} step 1
                    #{STEP_KEYWORD} step 2"
        background = clazz.new(source)

        source = "#{OUTLINE_KEYWORD}:
                    #{STEP_KEYWORD} step 1
                    #{STEP_KEYWORD} step 2
                  #{EXAMPLE_KEYWORD}:
                    | param |
                    | value |"
        outline_1 = CukeModeler::Outline.new(source)

        source = "#{OUTLINE_KEYWORD}:
                    #{STEP_KEYWORD} step 2
                    #{STEP_KEYWORD} step 1
                  #{EXAMPLE_KEYWORD}:
                    | param |
                    | value |"
        outline_2 = CukeModeler::Outline.new(source)


        expect(background).to eq(outline_1)
        expect(background).to_not eq(outline_2)
      end

    end


    describe 'background output' do

      it 'can be remade from its own output' do
        source = "#{BACKGROUND_KEYWORD}: A background with everything it could have

                  Including a description
                  and then some.

                    #{STEP_KEYWORD} a step
                      | value |
                    #{STEP_KEYWORD} another step
                      \"\"\"
                      some string
                      \"\"\""
        background = clazz.new(source)

        background_output = background.to_s
        remade_background_output = clazz.new(background_output).to_s

        expect(remade_background_output).to eq(background_output)
      end


      context 'from source text' do

        it 'can output an empty background' do
          source = ["#{BACKGROUND_KEYWORD}:"]
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{BACKGROUND_KEYWORD}:"])
        end

        it 'can output a background that has a name' do
          source = ["#{BACKGROUND_KEYWORD}: test background"]
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{BACKGROUND_KEYWORD}: test background"])
        end

        it 'can output a background that has a description' do
          source = ["#{BACKGROUND_KEYWORD}:",
                    'Some description.',
                    'Some more description.']
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{BACKGROUND_KEYWORD}:",
                                           '',
                                           'Some description.',
                                           'Some more description.'])
        end

        it 'can output a background that has steps' do
          source = ["#{BACKGROUND_KEYWORD}:",
                    "#{STEP_KEYWORD} a step",
                    '|value|',
                    "#{STEP_KEYWORD} another step",
                    '"""',
                    'some string',
                    '"""']
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{BACKGROUND_KEYWORD}:",
                                           "  #{STEP_KEYWORD} a step",
                                           '    | value |',
                                           "  #{STEP_KEYWORD} another step",
                                           '    """',
                                           '    some string',
                                           '    """'])
        end

        it 'can output a background that has everything' do
          source = ["#{BACKGROUND_KEYWORD}: A background with everything it could have",
                    'Including a description',
                    'and then some.',
                    "#{STEP_KEYWORD} a step",
                    '|value|',
                    "#{STEP_KEYWORD} another step",
                    '"""',
                    'some string',
                    '"""']
          source = source.join("\n")
          background = clazz.new(source)

          background_output = background.to_s.split("\n", -1)

          expect(background_output).to eq(["#{BACKGROUND_KEYWORD}: A background with everything it could have",
                                           '',
                                           'Including a description',
                                           'and then some.',
                                           '',
                                           "  #{STEP_KEYWORD} a step",
                                           '    | value |',
                                           "  #{STEP_KEYWORD} another step",
                                           '    """',
                                           '    some string',
                                           '    """'])
        end

      end


      context 'from abstract instantiation' do

        let(:background) { clazz.new }


        it 'can output a background that has only steps' do
          background.steps = [CukeModeler::Step.new]

          expect { background.to_s }.to_not raise_error
        end

      end

    end

  end

end
