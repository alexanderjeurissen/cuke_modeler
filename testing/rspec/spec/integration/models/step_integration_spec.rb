require "#{File.dirname(__FILE__)}/../../spec_helper"


describe 'Step, Integration' do

  let(:clazz) { CukeModeler::Step }
  let(:minimum_viable_gherkin) { "#{STEP_KEYWORD} a step" }
  let(:maximum_viable_gherkin_table) do
    "#{STEP_KEYWORD} a step
       | value1 |
       | value2 |"
  end
  let(:maximum_viable_gherkin_doc_string) do
    "#{STEP_KEYWORD} a step
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
        source_text = "Y'know a step"

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.keyword).to eq("Y'know")
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = "bad step text\n And a step\n @foo"

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_step\.feature'/)
    end

    describe 'parsing data' do

      context 'with minimum viable Gherkin' do

        let(:source_text) { minimum_viable_gherkin }

        it 'stores the original data generated by the parsing adapter' do
          step = clazz.new(source_text)
          data = step.parsing_data

          expect(data.keys).to match_array([:location, :keyword, :text, :id])
          expect(data[:text]).to eq('a step')
        end

      end

      context 'with maximum viable Gherkin' do

        context 'that has a table' do
          let(:source_text) { maximum_viable_gherkin_table }

          it 'stores the original data generated by the parsing adapter (with a table)' do
            step = clazz.new(source_text)
            data = step.parsing_data

            expect(data.keys).to match_array([:location, :keyword, :text, :data_table, :id])
            expect(data[:text]).to eq('a step')
          end
        end

        context 'that has a doc string' do
          let(:source_text) { maximum_viable_gherkin_doc_string }

          it 'stores the original data generated by the parsing adapter (with a doc string)' do
            step = clazz.new(source_text)
            data = step.parsing_data

            expect(data.keys).to match_array([:location, :keyword, :text, :doc_string, :id])
            expect(data[:text]).to eq('a step')
          end

        end
      end
    end

    describe 'model population' do

      context 'from source text' do

        let(:source_text) { "#{STEP_KEYWORD} a step" }
        let(:step) { clazz.new(source_text) }


        it "models the step's keyword" do
          expect(step.keyword).to eq(STEP_KEYWORD)
        end

        it "models the step's text" do
          expect(step.text).to eq('a step')
        end

        it "models the step's source line" do
          source_text = "#{FEATURE_KEYWORD}:

                           #{SCENARIO_KEYWORD}: foo
                             #{STEP_KEYWORD} step"
          step = CukeModeler::Feature.new(source_text).tests.first.steps.first

          expect(step.source_line).to eq(4)
        end


        context 'with no block' do

          let(:source_text) { "#{STEP_KEYWORD} a step" }
          let(:step) { clazz.new(source_text) }


          it "models the step's block" do
            expect(step.block).to be_nil
          end

        end

        context 'a step with a table' do

          let(:source_text) {
            "#{STEP_KEYWORD} a step
               | value 1 |
               | value 2 |"
          }
          let(:step) { clazz.new(source_text) }


          it "models the step's table" do
            table_cell_values = step.block.rows.collect { |row| row.cells.collect { |cell| cell.value } }

            expect(table_cell_values).to eq([['value 1'], ['value 2']])
          end

        end

        context 'a step with a doc string' do

          let(:source_text) {
            "#{STEP_KEYWORD} a step
               \"\"\"
               some text
               \"\"\""
          }
          let(:step) { clazz.new(source_text) }


          it "models the step's doc string" do
            doc_string = step.block

            expect(doc_string.content).to eq('some text')
          end

        end

      end

    end


    it 'properly sets its child models' do
      source_1 = "#{STEP_KEYWORD} a step
                  \"\"\"
                  a doc string
                  \"\"\""
      source_2 = "#{STEP_KEYWORD} a step
                  | a block|"

      step_1 = clazz.new(source_1)
      step_2 = clazz.new(source_2)


      doc_string = step_1.block
      table = step_2.block

      expect(doc_string.parent_model).to equal(step_1)
      expect(table.parent_model).to equal(step_2)
    end


    describe 'step comparison' do

      context 'a step that has text' do

        let(:step_text) { "#{STEP_KEYWORD} a step" }
        let(:base_step) { clazz.new(step_text) }

        context 'compared to a step that has the same text' do

          let(:compared_step) { clazz.new(step_text) }

          it 'considers them to be equal' do
            assert_bidirectional_equality(base_step, compared_step)
          end

        end

        context 'compared to a step that has different text' do

          let(:compared_step) { clazz.new(step_text + ' plus some more') }

          it 'considers them to not be equal' do
            assert_bidirectional_inequality(base_step, compared_step)
          end

        end

        context 'compared to a step that has a table' do

          let(:compared_step) { clazz.new(step_text + "\n | foo |") }

          it 'considers them to not be equal' do
            assert_bidirectional_inequality(base_step, compared_step)
          end

        end

        context 'compared to a step that has a doc string' do

          let(:compared_step) { clazz.new(step_text + "\n \"\"\"\n foo\n\"\"\"") }

          it 'considers them to not be equal' do
            assert_bidirectional_inequality(base_step, compared_step)
          end

        end


        context 'and has table' do

          let(:step_text) { "#{STEP_KEYWORD} a step\n | foo |" }
          let(:base_step) { clazz.new(step_text) }

          context 'compared to a step that has the same table' do

            let(:compared_step) { clazz.new(step_text) }

            it 'considers them to be equal' do
              assert_bidirectional_equality(base_step, compared_step)
            end

          end

          context 'compared to a step that has a different table' do

            let(:compared_step) { clazz.new(step_text + "\n | a different table |") }

            it 'considers them to not be equal' do
              assert_bidirectional_inequality(base_step, compared_step)
            end

          end

        end


        context 'and has a doc string' do

          let(:content) { 'foo' }
          let(:base_step) { clazz.new("#{step_text}\n\"\"\"\n#{content}\n\"\"\"") }

          context 'compared to a step that has the same doc string' do

            let(:compared_step) { clazz.new("#{step_text}\n\"\"\"\n#{content}\n\"\"\"") }

            it 'considers them to be equal' do
              assert_bidirectional_equality(base_step, compared_step)
            end

          end

          context 'compared to a step that has a different doc string' do

            let(:compared_step) { clazz.new("#{step_text}\n\"\"\"\n#{content + 'different'}\n\"\"\"") }

            it 'considers them to not be equal' do
              assert_bidirectional_inequality(base_step, compared_step)
            end

          end

          context 'and has a content type' do

            let(:content_type) { 'foo' }
            let(:base_step) { clazz.new("#{step_text}\n\"\"\" #{content_type}\n#{content}\n\"\"\"") }


            context 'compared to a step that has the same content type' do

              let(:compared_step) { clazz.new("#{step_text}\n\"\"\" #{content_type}\n#{content}\n\"\"\"") }

              it 'considers them to be equal' do
                assert_bidirectional_equality(base_step, compared_step)
              end

            end

            context 'compared to a step that has a different content type' do

              let(:compared_step) { clazz.new("#{step_text}\n\"\"\" different #{content_type}\n#{content}\n\"\"\"") }

              it 'considers them to not be equal' do
                assert_bidirectional_inequality(base_step, compared_step)
              end

            end

          end

        end

      end

      it 'ignores steps keywords when comparing steps' do
        source_1 = "#{GIVEN_KEYWORD} a step"
        source_2 = "#{THEN_KEYWORD}  a step"

        step_1 = clazz.new(source_1)
        step_2 = clazz.new(source_2)


        expect(step_1).to eq(step_2)
      end

    end


    describe 'getting ancestors' do

      before(:each) do
        CukeModeler::FileHelper.create_feature_file(text: source_gherkin,
                                                    name: 'step_test_file',
                                                    directory: test_directory)
      end


      let(:test_directory) { CukeModeler::FileHelper.create_directory }
      let(:source_gherkin) {
        "#{FEATURE_KEYWORD}: Test feature

           #{SCENARIO_KEYWORD}: Test test
             #{STEP_KEYWORD} a step:"
      }

      let(:directory_model) { CukeModeler::Directory.new(test_directory) }
      let(:step_model) { directory_model.feature_files.first.feature.tests.first.steps.first }


      it 'can get its directory' do
        ancestor = step_model.get_ancestor(:directory)

        expect(ancestor).to equal(directory_model)
      end

      it 'can get its feature file' do
        ancestor = step_model.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory_model.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = step_model.get_ancestor(:feature)

        expect(ancestor).to equal(directory_model.feature_files.first.feature)
      end


      context 'a step that is part of a scenario' do

        let(:test_directory) { CukeModeler::FileHelper.create_directory }
        let(:source_gherkin) {
          "#{FEATURE_KEYWORD}: Test feature

             #{SCENARIO_KEYWORD}: Test scenario
               #{STEP_KEYWORD} a step"
        }

        let(:directory_model) { CukeModeler::Directory.new(test_directory) }
        let(:step_model) { directory_model.feature_files.first.feature.tests.first.steps.first }


        it 'can get its scenario' do
          ancestor = step_model.get_ancestor(:scenario)

          expect(ancestor).to equal(directory_model.feature_files.first.feature.tests.first)
        end

      end

      context 'a step that is part of an outline' do

        let(:test_directory) { CukeModeler::FileHelper.create_directory }
        let(:source_gherkin) {
          "#{FEATURE_KEYWORD}: Test feature

             #{OUTLINE_KEYWORD}: Test outline
               #{STEP_KEYWORD} a step
             #{EXAMPLE_KEYWORD}:
               | param |
               | value |"
        }

        let(:directory_model) { CukeModeler::Directory.new(test_directory) }
        let(:step_model) { directory_model.feature_files.first.feature.tests.first.steps.first }


        it 'can get its outline' do
          ancestor = step_model.get_ancestor(:outline)

          expect(ancestor).to equal(directory_model.feature_files.first.feature.tests.first)
        end

      end

      context 'a step that is part of a background' do

        let(:test_directory) { CukeModeler::FileHelper.create_directory }
        let(:source_gherkin) {
          "#{FEATURE_KEYWORD}: Test feature

             #{BACKGROUND_KEYWORD}: Test background
               #{STEP_KEYWORD} a step"
        }

        let(:directory_model) { CukeModeler::Directory.new(test_directory) }
        let(:step_model) { directory_model.feature_files.first.feature.background.steps.first }


        it 'can get its background' do
          ancestor = step_model.get_ancestor(:background)

          expect(ancestor).to equal(directory_model.feature_files.first.feature.background)
        end

      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = step_model.get_ancestor(:example)

        expect(ancestor).to be_nil
      end

    end


    describe 'step output' do

      context 'from source text' do

        context 'with no block' do

          let(:source_text) { ["#{STEP_KEYWORD} a step"].join("\n") }
          let(:step) { clazz.new(source_text) }

          it 'can output a step' do
            step_output = step.to_s.split("\n", -1)

            expect(step_output).to eq(["#{STEP_KEYWORD} a step"])
          end

          it 'can be remade from its own output' do
            step_output = step.to_s
            remade_step_output = clazz.new(step_output).to_s

            expect(remade_step_output).to eq(step_output)
          end

        end

        context 'a step with a table' do

          let(:source_text) {
            ["#{STEP_KEYWORD} a step",
             '  | value1 | value2 |',
             '  | value3 | value4 |'].join("\n")
          }
          let(:step) { clazz.new(source_text) }


          it 'can output a step that has a table' do
            step_output = step.to_s.split("\n", -1)

            expect(step_output).to eq(["#{STEP_KEYWORD} a step",
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

          let(:source_text) {
            ["#{STEP_KEYWORD} a step",
             '  """',
             '  some text',
             '  """'].join("\n")
          }
          let(:step) { clazz.new(source_text) }


          it 'can output a step that has a doc string' do
            step_output = step.to_s.split("\n", -1)

            expect(step_output).to eq(["#{STEP_KEYWORD} a step",
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
