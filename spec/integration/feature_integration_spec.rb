require 'spec_helper'

SimpleCov.command_name('Feature') unless RUBY_VERSION.to_s < '1.9.0'

describe 'Feature, Integration' do

  let(:clazz) { CukeModeler::Feature }
  let(:feature) { clazz.new }


  describe 'common behavior' do

    it_should_behave_like 'a modeled element, integration'

  end

  describe 'unique behavior' do

    it 'properly sets its child elements' do
      source = ['@a_tag',
                'Feature: Test feature',
                '  Background: Test background',
                '  Scenario: Test scenario',
                '  Scenario Outline: Test outline',
                '  Examples: Test Examples',
                '    | param |',
                '    | value |']
      source = source.join("\n")


      feature = clazz.new(source)
      background = feature.background
      scenario = feature.tests[0]
      outline = feature.tests[1]
      tag = feature.tags[0]


      expect(outline.parent_model).to equal(feature)
      expect(scenario.parent_model).to equal(feature)
      expect(background.parent_model).to equal(feature)
      expect(tag.parent_model).to equal(feature)
    end

    it 'can selectively access its scenarios and outlines' do
      scenarios = [CukeModeler::Scenario.new, CukeModeler::Scenario.new]
      outlines = [CukeModeler::Outline.new, CukeModeler::Outline.new]

      feature.tests = scenarios + outlines

      expect(feature.scenarios).to match_array(scenarios)
      expect(feature.outlines).to match_array(outlines)
    end


    describe 'model population' do

      context 'from source text' do

        it "models the feature's source line" do
          source_text = "Feature:"
          feature = CukeModeler::Feature.new(source_text)

          expect(feature.source_line).to eq(1)
        end


        context 'a filled feature' do

          let(:source_text) { '@tag_1 @tag_2
                               Feature: Feature Foo

                                 Some feature description.

                               Some more.
                                   And some more.

                                 Background: The background
                                   * some setup step

                                 Scenario: Scenario 1
                                   * a step

                                 Scenario Outline: Outline 1
                                   * a step
                                 Examples:
                                   | param |
                                   | value |

                                 Scenario: Scenario 2
                                   * a step

                                 Scenario Outline: Outline 2
                                   * a step
                                 Examples:
                                   | param |
                                   | value |' }
          let(:feature) { clazz.new(source_text) }


          it "models the feature's background" do
            expect(feature.background.name).to eq('The background')
          end

          it "models the feature's scenarios" do
            scenario_names = feature.scenarios.collect { |scenario| scenario.name }

            expect(scenario_names).to eq(['Scenario 1', 'Scenario 2'])
          end

          it "models the feature's outlines" do
            outline_names = feature.outlines.collect { |outline| outline.name }

            expect(outline_names).to eq(['Outline 1', 'Outline 2'])
          end

          it "models the feature's tags" do
            tag_names = feature.tags.collect { |tag| tag.name }

            expect(tag_names).to eq(['@tag_1', '@tag_2'])
          end

        end

        context 'an empty feature' do

          let(:source_text) { 'Feature:' }
          let(:feature) { clazz.new(source_text) }


          it "models the feature's background" do
            expect(feature.background).to be_nil
          end

          it "models the feature's scenarios" do
            expect(feature.scenarios).to eq([])
          end

          it "models the feature's outlines" do
            expect(feature.outlines).to eq([])
          end

          it "models the feature's tags" do
            expect(feature.tags).to eq([])
          end

        end

      end

    end


    it 'knows how many test cases it has' do
      source_1 = ['Feature: Test feature']
      source_1 = source_1.join("\n")

      source_2 = ['Feature: Test feature',
                  '  Scenario: Test scenario',
                  '  Scenario Outline: Test outline',
                  '    * a step',
                  '  Examples: Test examples',
                  '    |param|',
                  '    |value_1|',
                  '    |value_2|']
      source_2 = source_2.join("\n")

      feature_1 = clazz.new(source_1)
      feature_2 = clazz.new(source_2)


      expect(feature_1.test_case_count).to eq(0)
      expect(feature_2.test_case_count).to eq(3)
    end


    describe 'getting ancestors' do

      before(:each) do
        source = ['Feature: Test feature']
        source = source.join("\n")

        file_path = "#{@default_file_directory}/feature_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:feature) { directory.feature_files.first.feature }


      it 'can get its directory' do
        ancestor = feature.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'can get its feature file' do
        ancestor = feature.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory.feature_files.first)
      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = feature.get_ancestor(:test)

        expect(ancestor).to be_nil
      end

    end


    describe 'feature output' do

      it 'can be remade from its own output' do
        source = ['@tag1 @tag2 @tag3',
                  'Feature: A feature with everything it could have',
                  '',
                  'Including a description',
                  'and then some.',
                  '',
                  '  Background:',
                  '',
                  '  Background',
                  '  description',
                  '',
                  '    * a step',
                  '      | value1 |',
                  '    * another step ',
                  '',
                  '  @scenario_tag ',
                  '  Scenario:',
                  '',
                  '  Scenario ',
                  '  description ',
                  '',
                  '    * a step ',
                  '    * another step ',
                  '      """"',
                  '      some text ',
                  '      """',
                  '',
                  '  @outline_tag ',
                  '  Scenario Outline: ',
                  '',
                  '  Outline ',
                  '  description ',
                  '',
                  '    * a step ',
                  '      | value2 |',
                  '    * another step ',
                  '      """',
                  '      some text ',
                  '      """',
                  '',
                  '  @example_tag ',
                  '  Examples:',
                  '',
                  '  Example ',
                  '  description',
                  '',
                  '    | param |',
                  '    | value |']
        source = source.join(" \n")
        feature = clazz.new(source)

        feature_output = feature.to_s
        remade_feature_output = clazz.new(feature_output).to_s

        expect(remade_feature_output).to eq(feature_output)
      end


      context 'from source text' do

        it 'can output a feature that has tags' do
          source = ['@tag1 @tag2',
                    '@tag3',
                    'Feature:']
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n")

          expect(feature_output).to eq(['@tag1 @tag2 @tag3',
                                        'Feature:'])
        end

        it 'can output a feature that has a background' do
          source = ['Feature:',
                    'Background:',
                    '* a step']
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n")

          expect(feature_output).to eq(['Feature:',
                                        '',
                                        '  Background:',
                                        '    * a step'])
        end

        it 'can output a feature that has a scenario' do
          source = ['Feature:',
                    'Scenario:',
                    '* a step']
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n")

          expect(feature_output).to eq(['Feature:',
                                        '',
                                        '  Scenario:',
                                        '    * a step'])
        end

        it 'can output a feature that has an outline' do
          source = ['Feature:',
                    'Scenario Outline:',
                    '* a step',
                    'Examples:',
                    '|param|',
                    '|value|']
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n")

          expect(feature_output).to eq(['Feature:',
                                        '',
                                        '  Scenario Outline:',
                                        '    * a step',
                                        '',
                                        '  Examples:',
                                        '    | param |',
                                        '    | value |'])
        end

        it 'can output a feature that has everything' do
          source = ['@tag1 @tag2 @tag3',
                    'Feature: A feature with everything it could have',
                    'Including a description',
                    'and then some.',
                    'Background:',
                    'Background',
                    'description',
                    '* a step',
                    '|value1|',
                    '* another step',
                    '@scenario_tag',
                    'Scenario:',
                    'Scenario',
                    'description',
                    '* a step',
                    '* another step',
                    '"""',
                    'some text',
                    '"""',
                    '@outline_tag',
                    'Scenario Outline:',
                    'Outline ',
                    'description',
                    '* a step ',
                    '|value2|',
                    '* another step',
                    '"""',
                    'some text',
                    '"""',
                    '@example_tag',
                    'Examples:',
                    'Example',
                    'description',
                    '|param|',
                    '|value|']
          source = source.join("\n")
          feature = clazz.new(source)

          feature_output = feature.to_s.split("\n")

          expect(feature_output).to eq(['@tag1 @tag2 @tag3',
                                        'Feature: A feature with everything it could have',
                                        '',
                                        'Including a description',
                                        'and then some.',
                                        '',
                                        '  Background:',
                                        '',
                                        '  Background',
                                        '  description',
                                        '',
                                        '    * a step',
                                        '      | value1 |',
                                        '    * another step',
                                        '',
                                        '  @scenario_tag',
                                        '  Scenario:',
                                        '',
                                        '  Scenario',
                                        '  description',
                                        '',
                                        '    * a step',
                                        '    * another step',
                                        '      """',
                                        '      some text',
                                        '      """',
                                        '',
                                        '  @outline_tag',
                                        '  Scenario Outline:',
                                        '',
                                        '  Outline',
                                        '  description',
                                        '',
                                        '    * a step',
                                        '      | value2 |',
                                        '    * another step',
                                        '      """',
                                        '      some text',
                                        '      """',
                                        '',
                                        '  @example_tag',
                                        '  Examples:',
                                        '',
                                        '  Example',
                                        '  description',
                                        '',
                                        '    | param |',
                                        '    | value |'])
        end

      end


      context 'from abstract instantiation' do

        let(:feature) { clazz.new }


        it 'can output a feature that has only tags' do
          feature.tags = [CukeModeler::Tag.new]

          expect { feature.to_s }.to_not raise_error
        end

        it 'can output a feature that has only a background' do
          feature.background = [CukeModeler::Background.new]

          expect { feature.to_s }.to_not raise_error
        end

        it 'can output a feature that has only scenarios' do
          feature.tests = [CukeModeler::Scenario.new]

          expect { feature.to_s }.to_not raise_error
        end

        it 'can output a feature that has only outlines' do
          feature.tests = [CukeModeler::Outline.new]

          expect { feature.to_s }.to_not raise_error
        end

      end

    end

  end

end
