module CukeModeler

  # NOT A PART OF THE PUBLIC API
  # A mix-in module containing methods used by models that are parsed from source text.

  module Parsed

    # The parsing data for this element that was generated by the parsing engine (i.e. the *gherkin* gem)
    attr_accessor :parsing_data


    private


    def populate_parsing_data(model, parsed_model_data)
      model.parsing_data = parsed_model_data['cuke_modeler_parsing_data']
    end

  end
end
