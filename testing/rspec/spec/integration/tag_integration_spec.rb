require "#{File.dirname(__FILE__)}/../spec_helper"


describe 'Tag, Integration' do

  let(:clazz) { CukeModeler::Tag }


  describe 'common behavior' do

    it_should_behave_like 'a model, integration'

  end

  describe 'unique behavior' do

    it 'can be instantiated with the minimum viable Gherkin' do
      source = '@a_tag'

      expect { clazz.new(source) }.to_not raise_error
    end

    it 'can parse text that uses a non-default dialect' do
      original_dialect = CukeModeler::Parsing.dialect
      CukeModeler::Parsing.dialect = 'en-au'

      begin
        source_text = '@foo'

        expect { @model = clazz.new(source_text) }.to_not raise_error

        # Sanity check in case modeling failed in a non-explosive manner
        expect(@model.name).to eq('@foo')
      ensure
        # Making sure that our changes don't escape a test and ruin the rest of the suite
        CukeModeler::Parsing.dialect = original_dialect
      end
    end

    it 'provides a descriptive filename when being parsed from stand alone text' do
      source = 'bad tag text'

      expect { clazz.new(source) }.to raise_error(/'cuke_modeler_stand_alone_tag\.feature'/)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin4 => true do
      tag = clazz.new('@a_tag')
      data = tag.parsing_data

      expect(data.keys).to match_array([:type, :location, :name])
      expect(data[:type]).to eq(:Tag)
    end

    it 'stores the original data generated by the parsing adapter', :gherkin3 => true do
      tag = clazz.new('@a_tag')
      data = tag.parsing_data

      expect(data.keys).to match_array([:type, :location, :name])
      expect(data[:type]).to eq('Tag')
    end

    it 'stores the original data generated by the parsing adapter', :gherkin2 => true do
      tag = clazz.new('@a_tag')
      data = tag.parsing_data

      expect(data.keys).to match_array(['name', 'line'])
      expect(data['name']).to eq('@a_tag')
    end


    describe 'getting ancestors' do

      before(:each) do
        source = "@feature_tag
                  #{@feature_keyword}: Test feature

                    #{@outline_keyword}: Test test
                      #{@step_keyword} a step

                    @example_tag
                    #{@example_keyword}: Test example
                      | a param |
                      | a value |"

        file_path = "#{@default_file_directory}/tag_test_file.feature"
        File.open(file_path, 'w') { |file| file.write(source) }
      end

      let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
      let(:tag) { directory.feature_files.first.feature.tests.first.examples.first.tags.first }
      let(:high_level_tag) { directory.feature_files.first.feature.tags.first }


      it 'can get its directory' do
        ancestor = tag.get_ancestor(:directory)

        expect(ancestor).to equal(directory)
      end

      it 'can get its feature file' do
        ancestor = tag.get_ancestor(:feature_file)

        expect(ancestor).to equal(directory.feature_files.first)
      end

      it 'can get its feature' do
        ancestor = tag.get_ancestor(:feature)

        expect(ancestor).to equal(directory.feature_files.first.feature)
      end

      context 'a tag that is part of a scenario' do

        before(:each) do
          source = "#{@feature_keyword}: Test feature
                      
                      @a_tag
                      #{@scenario_keyword}: Test scenario
                        #{@step_keyword} a step"

          file_path = "#{@default_file_directory}/tag_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:tag) { directory.feature_files.first.feature.tests.first.tags.first }


        it 'can get its scenario' do
          ancestor = tag.get_ancestor(:scenario)

          expect(ancestor).to equal(directory.feature_files.first.feature.tests.first)
        end

      end

      context 'a tag that is part of an outline' do

        before(:each) do
          source = "#{@feature_keyword}: Test feature
                      
                      @a_tag
                      #{@outline_keyword}: Test outline
                        #{@step_keyword} a step
                      #{@example_keyword}:
                        | param |
                        | value |"

          file_path = "#{@default_file_directory}/tag_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:tag) { directory.feature_files.first.feature.tests.first.tags.first }


        it 'can get its outline' do
          ancestor = tag.get_ancestor(:outline)

          expect(ancestor).to equal(directory.feature_files.first.feature.tests.first)
        end

      end

      context 'a tag that is part of an example' do

        before(:each) do
          source = "#{@feature_keyword}: Test feature
                      
                      #{@outline_keyword}: Test outline
                        #{@step_keyword} a step
                      @a_tag
                      #{@example_keyword}:
                        | param |
                        | value |"
          file_path = "#{@default_file_directory}/tag_test_file.feature"
          File.open(file_path, 'w') { |file| file.write(source) }
        end

        let(:directory) { CukeModeler::Directory.new(@default_file_directory) }
        let(:tag) { directory.feature_files.first.feature.tests.first.examples.first.tags.first }


        it 'can get its example' do
          ancestor = tag.get_ancestor(:example)

          expect(ancestor).to equal(directory.feature_files.first.feature.tests.first.examples.first)
        end

      end

      it 'returns nil if it does not have the requested type of ancestor' do
        ancestor = high_level_tag.get_ancestor(:example)

        expect(ancestor).to be_nil
      end

    end


    describe 'model population' do

      context 'from source text' do

        let(:source_text) { '@a_tag' }
        let(:tag) { clazz.new(source_text) }


        it "models the tag's name" do
          expect(tag.name).to eq('@a_tag')
        end

        it "models the tag's source line" do
          source_text = "#{@feature_keyword}:

                           @a_tag
                           #{@scenario_keyword}:
                             #{@step_keyword} step"
          tag = CukeModeler::Feature.new(source_text).tests.first.tags.first

          expect(tag.source_line).to eq(3)
        end

      end

    end


    describe 'tag output' do

      it 'can be remade from its own output' do
        source = '@some_tag'
        tag = clazz.new(source)

        tag_output = tag.to_s
        remade_tag_output = clazz.new(tag_output).to_s

        expect(remade_tag_output).to eq(tag_output)
      end


      context 'from source text' do

        it 'can output a tag' do
          source = '@a_tag'
          tag = clazz.new(source)

          expect(tag.to_s).to eq('@a_tag')
        end

      end

    end

  end

end
