require "#{File.dirname(__FILE__)}/../../spec_helper"


describe 'Scenario, Integration' do

  let(:clazz) { CukeModeler::Scenario }
  let(:minimum_viable_gherkin) { "#{SCENARIO_KEYWORD}:" }
  let(:maximum_viable_gherkin) do
    "@a_tag
     #{SCENARIO_KEYWORD}: test scenario

     Scenario
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
        source_text = 'Awww, look mate: Scenario name'

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.name).to eq('Scenario name')
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad scenario text \n #{SCENARIO_KEYWORD}:\n And a step\n @foo "

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_scenario\.feature'/)
    end

    describe 'parsing data' do

      context 'with minimum viable Gherkin' do

        let(:source_text) { minimum_viable_gherkin }

        it 'stores the original data generated by the parsing adapter' do
          scenario = clazz.new(source_text)
          data = scenario.parsing_data

          expect(data.keys).to match_array([:scenario])
          expect(data[:scenario].keys).to match_array([:id, :keyword, :location, :name])
          expect(data[:scenario][:keyword]).to eq(SCENARIO_KEYWORD)
        end

      end

      context 'with maximum viable Gherkin' do

        let(:source_text) { maximum_viable_gherkin }

        it 'stores the original data generated by the parsing adapter' do
          scenario = clazz.new(source_text)
          data = scenario.parsing_data

          expect(data.keys).to match_array([:scenario])
          expect(data[:scenario].keys).to match_array([:description, :id, :keyword, :location, :name, :steps, :tags])
          expect(data[:scenario][:keyword]).to eq(SCENARIO_KEYWORD)
        end

      end

    end

    it 'properly sets its child models' do
      source = "@a_tag
                #{SCENARIO_KEYWORD}: Test scenario
                  #{STEP_KEYWORD} a step"

      scenario = clazz.new(source)
      step = scenario.steps.first
      tag = scenario.tags.first

      expect(step.parent_model).to equal(scenario)
      expect(tag.parent_model).to equal(scenario)
    end

    it 'trims whitespace from its source description' do
      source = ["#{SCENARIO_KEYWORD}:",
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

      scenario = clazz.new(source)
      description = scenario.description.split("\n", -1)

      expect(description).to eq(['     description line 1',
                                 '',
                                 'description line 2',
                                 '  description line 3'])
    end


    describe 'getting ancestors' do

      before(:each) do
        CukeModeler::FileHelper.create_feature_file(text: source_gherkin, name: 'scenario_test_file', directory: test_directory)
      end


      let(:test_directory) { CukeModeler::FileHelper.create_directory }
      let(:source_gherkin) {
        "#{FEATURE_KEYWORD}: Test feature

           #{SCENARIO_KEYWORD}: Test test
             #{STEP_KEYWORD} a step"
      }

      let(:directory_model) { CukeModeler::Directory.new(test_directory) }
      let(:scenario_model) { directory_model.feature_files.first.feature.tests.first }


      it 'can get its directory' do
        ancestor = scenario_model.get_ancestor(:directory)

        expect(ancestor).to equal(directory_model)
      end

      it 'can get its feature file' do
        ancestor = scenario_model.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory_model.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = scenario_model.get_ancestor(:feature)

        expect(ancestor).to equal(directory_model.feature_files.first.feature)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = scenario_model.get_ancestor(:test)

        expect(ancestor).to be_nil
      end

    end


    describe 'model population' do

      context 'from source text' do

        let(:source_text) { "#{SCENARIO_KEYWORD}:" }
        let(:scenario) { clazz.new(source_text) }


        it "models the scenario's keyword" do
          expect(scenario.keyword).to eq(SCENARIO_KEYWORD)
        end

        it "models the scenario's source line" do
          source_text = "#{FEATURE_KEYWORD}:

                           #{SCENARIO_KEYWORD}: foo
                             #{STEP_KEYWORD} step"
          scenario = CukeModeler::Feature.new(source_text).tests.first

          expect(scenario.source_line).to eq(3)
        end


        context 'a filled scenario' do

          let(:source_text) {
            "@tag1 @tag2 @tag3
               #{SCENARIO_KEYWORD}: Scenario name

                   Scenario description.

                 Some more.
                     Even more.

               #{STEP_KEYWORD} a step
               #{STEP_KEYWORD} another step"
          }
          let(:scenario) { clazz.new(source_text) }


          it "models the scenario's name" do
            expect(scenario.name).to eq('Scenario name')
          end

          it "models the scenario's description" do
            description = scenario.description.split("\n", -1)

            expect(description).to eq(['  Scenario description.',
                                       '',
                                       'Some more.',
                                       '    Even more.'])
          end

          it "models the scenario's steps" do
            step_names = scenario.steps.collect { |step| step.text }

            expect(step_names).to eq(['a step', 'another step'])
          end

          it "models the scenario's tags" do
            tag_names = scenario.tags.collect { |tag| tag.name }

            expect(tag_names).to eq(['@tag1', '@tag2', '@tag3'])
          end

        end

        context 'an empty scenario' do

          let(:source_text) { "#{SCENARIO_KEYWORD}:" }
          let(:scenario) { clazz.new(source_text) }


          it "models the scenario's name" do
            expect(scenario.name).to eq('')
          end

          it "models the scenario's description" do
            expect(scenario.description).to eq('')
          end

          it "models the scenario's steps" do
            expect(scenario.steps).to eq([])
          end

          it "models the scenario's tags" do
            expect(scenario.tags).to eq([])
          end

        end

      end

    end


    describe 'comparison' do

      it 'is equal to a background with the same steps' do
        source = "#{SCENARIO_KEYWORD}:
                      #{STEP_KEYWORD} step 1
                      #{STEP_KEYWORD} step 2"
        scenario = clazz.new(source)

        source = "#{BACKGROUND_KEYWORD}:
                      #{STEP_KEYWORD} step 1
                      #{STEP_KEYWORD} step 2"
        background_1 = CukeModeler::Background.new(source)

        source = "#{BACKGROUND_KEYWORD}:
                      #{STEP_KEYWORD} step 2
                      #{STEP_KEYWORD} step 1"
        background_2 = CukeModeler::Background.new(source)


        expect(scenario).to eq(background_1)
        expect(scenario).to_not eq(background_2)
      end

      it 'is equal to a scenario with the same steps' do
        source = "#{SCENARIO_KEYWORD}:
                      #{STEP_KEYWORD} step 1
                      #{STEP_KEYWORD} step 2"
        scenario_1 = clazz.new(source)

        source = "#{SCENARIO_KEYWORD}:
                      #{STEP_KEYWORD} step 1
                      #{STEP_KEYWORD} step 2"
        scenario_2 = clazz.new(source)

        source = "#{SCENARIO_KEYWORD}:
                      #{STEP_KEYWORD} step 2
                      #{STEP_KEYWORD} step 1"
        scenario_3 = clazz.new(source)


        expect(scenario_1).to eq(scenario_2)
        expect(scenario_1).to_not eq(scenario_3)
      end

      it 'is equal to an outline with the same steps' do
        source = "#{SCENARIO_KEYWORD}:
                      #{STEP_KEYWORD} step 1
                      #{STEP_KEYWORD} step 2"
        scenario = clazz.new(source)

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


        expect(scenario).to eq(outline_1)
        expect(scenario).to_not eq(outline_2)
      end

    end


    describe 'scenario output' do

      it 'can be remade from its own output' do
        source = "@tag1 @tag2 @tag3
                  #{SCENARIO_KEYWORD}: A scenario with everything it could have

                  Including a description
                  and then some.

                    #{STEP_KEYWORD} a step
                      | value |
                    #{STEP_KEYWORD} another step
                      \"\"\"
                      some string
                      \"\"\""
        scenario = clazz.new(source)

        scenario_output = scenario.to_s
        remade_scenario_output = clazz.new(scenario_output).to_s

        expect(remade_scenario_output).to eq(scenario_output)
      end


      context 'from source text' do

        it 'can output an empty scenario' do
          source = ["#{SCENARIO_KEYWORD}:"]
          source = source.join("\n")
          scenario = clazz.new(source)

          scenario_output = scenario.to_s.split("\n", -1)

          expect(scenario_output).to eq(["#{SCENARIO_KEYWORD}:"])
        end

        it 'can output a scenario that has a name' do
          source = ["#{SCENARIO_KEYWORD}: test scenario"]
          source = source.join("\n")
          scenario = clazz.new(source)

          scenario_output = scenario.to_s.split("\n", -1)

          expect(scenario_output).to eq(["#{SCENARIO_KEYWORD}: test scenario"])
        end

        it 'can output a scenario that has a description' do
          source = ["#{SCENARIO_KEYWORD}:",
                    'Some description.',
                    'Some more description.']
          source = source.join("\n")
          scenario = clazz.new(source)

          scenario_output = scenario.to_s.split("\n", -1)

          expect(scenario_output).to eq(["#{SCENARIO_KEYWORD}:",
                                         '',
                                         'Some description.',
                                         'Some more description.'])
        end

        it 'can output a scenario that has steps' do
          source = ["#{SCENARIO_KEYWORD}:",
                    "#{STEP_KEYWORD} a step",
                    '|value|',
                    "#{STEP_KEYWORD} another step",
                    '"""',
                    'some string',
                    '"""']
          source = source.join("\n")
          scenario = clazz.new(source)

          scenario_output = scenario.to_s.split("\n", -1)

          expect(scenario_output).to eq(["#{SCENARIO_KEYWORD}:",
                                         "  #{STEP_KEYWORD} a step",
                                         '    | value |',
                                         "  #{STEP_KEYWORD} another step",
                                         '    """',
                                         '    some string',
                                         '    """'])
        end

        it 'can output a scenario that has tags' do
          source = ['@tag1 @tag2',
                    '@tag3',
                    "#{SCENARIO_KEYWORD}:"]
          source = source.join("\n")
          scenario = clazz.new(source)

          scenario_output = scenario.to_s.split("\n", -1)

          expect(scenario_output).to eq(['@tag1 @tag2 @tag3',
                                         "#{SCENARIO_KEYWORD}:"])
        end

        it 'can output a scenario that has everything' do
          source = ['@tag1 @tag2 @tag3',
                    "#{SCENARIO_KEYWORD}: A scenario with everything it could have",
                    'Including a description',
                    'and then some.',
                    "#{STEP_KEYWORD} a step",
                    '|value|',
                    "#{STEP_KEYWORD} another step",
                    '"""',
                    'some string',
                    '"""']
          source = source.join("\n")
          scenario = clazz.new(source)

          scenario_output = scenario.to_s.split("\n", -1)

          expect(scenario_output).to eq(['@tag1 @tag2 @tag3',
                                         "#{SCENARIO_KEYWORD}: A scenario with everything it could have",
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

        let(:scenario) { clazz.new }


        it 'can output a scenario that has only tags' do
          scenario.tags = [CukeModeler::Tag.new]

          expect { scenario.to_s }.to_not raise_error
        end

        it 'can output a scenario that has only steps' do
          scenario.steps = [CukeModeler::Step.new]

          expect { scenario.to_s }.to_not raise_error
        end

      end

    end

  end

end
