require "#{File.dirname(__FILE__)}/../spec_helper"


describe 'Row, Integration' do

  let(:clazz) { CukeModeler::Row }


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end


  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin' do
      source = '| a | row |'

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'can parse text that uses a non-default dialect' do
      original_dialect = CukeModeler::Parsing.dialect
      CukeModeler::Parsing.dialect = 'en-au'

      begin
        source_text = '| a | row |'

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.cells.last.value).to eq('row')
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = " |bad |row| text| \n @foo "

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_row\.feature'/)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4_5 => true do
      example_row = clazz.new("| a | row |")
      data = example_row.parsing_data

      expect(data.keys).to match_array([:type, :location, :cells])
      expect(data[:type]).to eq(:TableRow)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      example_row = clazz.new("| a | row |")
      data = example_row.parsing_data

      expect(data.keys).to match_array([:type, :location, :cells])
      expect(data[:type]).to eq('TableRow')
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      example_row = clazz.new("| a | row |")
      data = example_row.parsing_data

      expect(data.keys).to match_array(['cells', 'line'])
      expect(data['line']).to eq(5)
    end

    it 'properly sets its child models' do
      source = '| cell 1 | cell 2 |'

      row = clazz.new(source)
      cell_1 = row.cells.first
      cell_2 = row.cells.last

      expect(cell_1.parent_model).to equal(row)
      expect(cell_2.parent_model).to equal(row)
    end


    describe 'getting ancestors' do

      before(:each) do
        CukeModeler::FileHelper.create_feature_file(:text => source_gherkin, :name => 'row_test_file', :directory => test_directory)
      end


      let(:test_directory) { CukeModeler::FileHelper.create_directory }
      let(:source_gherkin) { "#{FEATURE_KEYWORD}: Test feature

                                #{SCENARIO_KEYWORD}: Test test
                                  #{STEP_KEYWORD} a step:
                                    | a | table |"
      }

      let(:directory_model) { CukeModeler::Directory.new(test_directory) }
      let(:row_model) { directory_model.feature_files.first.feature.tests.first.steps.first.block.rows.first }


      it 'can get its directory' do
        ancestor = row_model.get_ancestor(:directory)

        expect(ancestor).to equal(directory_model)
      end

      it 'can get its feature file' do
        ancestor = row_model.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory_model.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = row_model.get_ancestor(:feature)

        expect(ancestor).to equal(directory_model.feature_files.first.feature)
      end

      it 'can get its step' do
        ancestor = row_model.get_ancestor(:step)

        expect(ancestor).to equal(directory_model.feature_files.first.feature.tests.first.steps.first)
      end

      it 'can get its table' do
        ancestor = row_model.get_ancestor(:table)

        expect(ancestor).to equal(directory_model.feature_files.first.feature.tests.first.steps.first.block)
      end

      context 'a row that is part of a scenario' do

        let(:test_directory) { CukeModeler::FileHelper.create_directory }
        let(:source_gherkin) { "#{FEATURE_KEYWORD}: Test feature

                                  #{SCENARIO_KEYWORD}: Test test
                                    #{STEP_KEYWORD} a step:
                                      | a | table |"
        }

        let(:directory_model) { CukeModeler::Directory.new(test_directory) }
        let(:row_model) { directory_model.feature_files.first.feature.tests.first.steps.first.block.rows.first }


        it 'can get its scenario' do
          ancestor = row_model.get_ancestor(:scenario)

          expect(ancestor).to equal(directory_model.feature_files.first.feature.tests.first)
        end

      end


      context 'a row that is part of a background' do

        let(:test_directory) { CukeModeler::FileHelper.create_directory }
        let(:source_gherkin) { "#{FEATURE_KEYWORD}: Test feature

                                #{BACKGROUND_KEYWORD}: Test background
                                  #{STEP_KEYWORD} a step:
                                    | a | table |"
        }

        let(:directory_model) { CukeModeler::Directory.new(test_directory) }
        let(:row_model) { directory_model.feature_files.first.feature.background.steps.first.block.rows.first }


        it 'can get its background' do
          ancestor = row_model.get_ancestor(:background)

          expect(ancestor).to equal(directory_model.feature_files.first.feature.background)
        end

      end

      context 'a row that is part of an outline' do

        let(:test_directory) { CukeModeler::FileHelper.create_directory }
        let(:source_gherkin) { "#{FEATURE_KEYWORD}: Test feature

                                #{OUTLINE_KEYWORD}: Test outline
                                  #{STEP_KEYWORD} a step
                                #{EXAMPLE_KEYWORD}:
                                  | param |
                                  | value |"
        }

        let(:directory_model) { CukeModeler::Directory.new(test_directory) }
        let(:row_model) { directory_model.feature_files.first.feature.tests.first.examples.first.rows.first }


        it 'can get its outline' do
          ancestor = row_model.get_ancestor(:outline)

          expect(ancestor).to equal(directory_model.feature_files.first.feature.tests.first)
        end

        it 'can get its example' do
          ancestor = row_model.get_ancestor(:example)

          expect(ancestor).to equal(directory_model.feature_files.first.feature.tests.first.examples.first)
        end

      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = row_model.get_ancestor(:outline)

        expect(ancestor).to be_nil
      end

    end


    describe 'model population' do

      context 'from source text' do

        let(:source_text) { '| cell 1 | cell 2 |' }
        let(:row) { clazz.new(source_text) }


        it "models the row's cells" do
          cell_values = row.cells.collect { |cell| cell.value }

          expect(cell_values).to match_array(['cell 1', 'cell 2'])
        end

        it "models the row's source line" do
          source_text = "#{FEATURE_KEYWORD}: Test feature

                           #{OUTLINE_KEYWORD}: Test outline
                             #{STEP_KEYWORD} a step
                           #{EXAMPLE_KEYWORD}:
                             | param |
                             | value |"
          row = CukeModeler::Feature.new(source_text).tests.first.examples.first.rows.first

          expect(row.source_line).to eq(6)
        end

      end

    end


    describe 'row output' do

      it 'can be remade from its own output' do
        source = "| value1 | value2 |"
        row = clazz.new(source)

        row_output = row.to_s
        remade_row_output = clazz.new(row_output).to_s

        expect(remade_row_output).to eq(row_output)
      end


      context 'from source text' do

        it 'can output a row' do
          source = '| some value |'
          row = clazz.new(source)

          expect(row.to_s).to eq('| some value |')
        end

        it 'can output a row with multiple cells' do
          source = '| some value | some other value |'
          row = clazz.new(source)

          expect(row.to_s).to eq('| some value | some other value |')
        end

      end

    end

  end

end
