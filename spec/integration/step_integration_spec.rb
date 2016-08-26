require 'spec_helper'


describe 'Step, Integration' do

  let(:clazz) { CukeModeler::Step }


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end

  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin' do
      source = '* a step'

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad step text\n And a step\n @foo"

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_step\.feature'/)
    end

    it 'stores the original data generated by the parsing adapter (with a table)', :gherkin4 => true do
      step = clazz.new("* test step\n|table|")
      data = step.parsing_data

      expect(data.keys).to match_array([:type, :location, :keyword, :text, :argument])
      expect(data[:type]).to eq(:Step)
    end

    it 'stores the original data generated by the parsing adapter (with a doc string)', :gherkin4 => true do
      step = clazz.new("* test step\n\"\"\"\na doc string\n\"\"\"")
      data = step.parsing_data

      expect(data.keys).to match_array([:type, :location, :keyword, :text, :argument])
      expect(data[:type]).to eq(:Step)
    end

    it 'stores the original data generated by the parsing adapter (with a table)', :gherkin3 => true do
      step = clazz.new("* test step\n|table|")
      data = step.parsing_data

      expect(data.keys).to match_array([:type, :location, :keyword, :text, :argument])
      expect(data[:type]).to eq(:Step)
    end

    it 'stores the original data generated by the parsing adapter (with a doc string)', :gherkin3 => true do
      step = clazz.new("* test step\n\"\"\"\na doc string\n\"\"\"")
      data = step.parsing_data

      expect(data.keys).to match_array([:type, :location, :keyword, :text, :argument])
      expect(data[:type]).to eq(:Step)
    end

    it 'stores the original data generated by the parsing adapter (with a table)', :gherkin2 => true do
      step = clazz.new("* test step\n|table|")
      data = step.parsing_data

      expect(data.keys).to match_array(['keyword', 'name', 'line', 'rows'])
      expect(data['keyword']).to eq('* ')
    end

    it 'stores the original data generated by the parsing adapter (with a doc string)', :gherkin2 => true do
      step = clazz.new("* test step\n\"\"\"\na doc string\n\"\"\"")
      data = step.parsing_data

      expect(data.keys).to match_array(['keyword', 'name', 'line', 'doc_string'])
      expect(data['keyword']).to eq('* ')
    end

    describe 'model population' do

      context 'from source text' do

        let(:source_text) { '* a step' }
        let(:step) { clazz.new(source_text) }


        it "models the step's keyword" do
          expect(step.keyword).to eq('*')
        end

        it "models the step's text" do
          expect(step.text).to eq('a step')
        end

        it "models the step's source line" do
          source_text = "Feature:

                           Scenario: foo
                             * step"
          step = CukeModeler::Feature.new(source_text).tests.first.steps.first

          expect(step.source_line).to eq(4)
        end


        context 'with no block' do

          let(:source_text) { '* a step' }
          let(:step) { clazz.new(source_text) }


          it "models the step's block" do
            expect(step.block).to be_nil
          end

        end

        context 'a step with a table' do

          let(:source_text) { '* a step
                                 | value 1 |
                                 | value 2 |' }
          let(:step) { clazz.new(source_text) }


          it "models the step's table" do
            table_cell_values = step.block.rows.collect { |row| row.cells.collect { |cell| cell.value } }

            expect(table_cell_values).to eq([['value 1'], ['value 2']])
          end

        end

        context 'a step with a doc string' do

          let(:source_text) { '* a step
                                 """
                                 some text
                                 """' }
          let(:step) { clazz.new(source_text) }


          it "models the step's doc string" do
            doc_string = step.block

            expect(doc_string.contents).to eq('some text')
          end

        end

      end

    end


    it 'properly sets its child models' do
      source_1 = ['* a step',
                  '"""',
                  'a doc string',
                  '"""']
      source_2 = ['* a step',
                  '| a block|']

      step_1 = clazz.new(source_1.join("\n"))
      step_2 = clazz.new(source_2.join("\n"))


      doc_string = step_1.block
      table = step_2.block

      expect(doc_string.parent_model).to equal(step_1)
      expect(table.parent_model).to equal(step_2)
    end


    describe 'step comparison' do

      it 'is equal to another Step that has the same text' do
        source_1 = '* a step'
        source_2 = '* a step'
        source_3 = '* a different step'

        step_1 = clazz.new(source_1)
        step_2 = clazz.new(source_2)
        step_3 = clazz.new(source_3)


        expect(step_1).to eq(step_2)
        expect(step_1).to_not eq(step_3)
      end

      it 'ignores steps keywords when comparing steps' do
        source_1 = 'Given a step'
        source_2 = 'Then  a step'

        step_1 = clazz.new(source_1)
        step_2 = clazz.new(source_2)


        expect(step_1).to eq(step_2)
      end

      it 'ignores step tables when comparing steps' do
        source_1 = '* a step'
        source_2 = "* a step\n|with a table|"

        step_1 = clazz.new(source_1)
        step_2 = clazz.new(source_2)


        expect(step_1).to eq(step_2)
      end

      it 'ignores step doc strings when comparing steps' do
        source_1 = '* a step'
        source_2 = "* a step\n\"\"\"\nwith a doc string\n\"\"\""


        step_1 = clazz.new(source_1)
        step_2 = clazz.new(source_2)


        expect(step_1).to eq(step_2)
      end

    end


    describe 'getting ancestors' do

      before(:each) do
        source = ['Feature: Test feature',
                  '',
                  '  Scenario: Test test',
                  '    * a step:']
        source = source.join("\n")

        file_path = "#{@default_file_directory}/step_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:step) { directory.feature_files.first.feature.tests.first.steps.first }


      it 'can get its directory' do
        ancestor = step.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'can get its feature file' do
        ancestor = step.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = step.get_ancestor(:feature)

        expect(ancestor).to equal(directory.feature_files.first.feature)
      end


      context 'a step that is part of a scenario' do

        before(:each) do
          source = 'Feature: Test feature
                      
                      Scenario: Test scenario
                        * a step'

          file_path = "#{@default_file_directory}/step_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:step) { directory.feature_files.first.feature.tests.first.steps.first }


        it 'can get its scenario' do
          ancestor = step.get_ancestor(:scenario)

          expect(ancestor).to equal(directory.feature_files.first.feature.tests.first)
        end

      end

      context 'a step that is part of an outline' do

        before(:each) do
          source = 'Feature: Test feature
                      
                      Scenario Outline: Test outline
                        * a step
                      Examples:
                        | param |
                        | value |'

          file_path = "#{@default_file_directory}/step_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:step) { directory.feature_files.first.feature.tests.first.steps.first }


        it 'can get its outline' do
          ancestor = step.get_ancestor(:outline)

          expect(ancestor).to equal(directory.feature_files.first.feature.tests.first)
        end

      end

      context 'a step that is part of a background' do

        before(:each) do
          source = 'Feature: Test feature
                      
                      Background: Test background
                        * a step'

          file_path = "#{@default_file_directory}/step_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:step) { directory.feature_files.first.feature.background.steps.first }


        it 'can get its background' do
          ancestor = step.get_ancestor(:background)

          expect(ancestor).to equal(directory.feature_files.first.feature.background)
        end

      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = step.get_ancestor(:example)

        expect(ancestor).to be_nil
      end

    end


    describe 'step output' do

      context 'from source text' do

        context 'with no block' do

          it 'can output a step' do
            source = ['* a step']
            source = source.join("\n")
            step = clazz.new(source)

            step_output = step.to_s.split("\n")

            expect(step_output).to eq(['* a step'])
          end

        end

        context 'a step with a table' do

          let(:source_text) { ['* a step',
                               '  | value1 | value2 |',
                               '  | value3 | value4 |'].join("\n") }
          let(:step) { clazz.new(source_text) }


          it 'can output a step that has a table' do
            step_output = step.to_s.split("\n")

            expect(step_output).to eq(['* a step',
                                       '  | value1 | value2 |',
                                       '  | value3 | value4 |'])

          end

          it 'can be remade from its own output' do
            step_output = step.to_s
            remade_step_output = clazz.new(step_output).to_s

            expect(remade_step_output).to eq(step_output)
          end

        end

        context 'a step with a doc string' do

          let(:source_text) { ['* a step',
                               '  """',
                               '  some text',
                               '  """'].join("\n") }
          let(:step) { clazz.new(source_text) }


          it 'can output a step that has a doc string' do
            step_output = step.to_s.split("\n")

            expect(step_output).to eq(['* a step',
                                       '  """',
                                       '  some text',
                                       '  """'])
          end

          it 'can be remade from its own output' do
            step_output = step.to_s
            remade_step_output = clazz.new(step_output).to_s

            expect(remade_step_output).to eq(step_output)
          end

        end

      end


      context 'from abstract instantiation' do

        let(:step) { clazz.new }


        it 'can output a step that has only a table' do
          step.block = CukeModeler::Table.new

          expect { step.to_s }.to_not raise_error
        end

        it 'can output a step that has only a doc string' do
          step.block = CukeModeler::DocString.new

          expect { step.to_s }.to_not raise_error
        end

      end

    end

  end

end
