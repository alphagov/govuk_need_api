module Search

  # A wrapper around a need that presents the information necessary to index
  # it, including knowledge of which fields we should index and how.
  class IndexableNeed

    class Field < Struct.new(:name, :type, :analyzed, :include_in_all)
      # Structs don't appear to work with question marks in symbols
      alias_method :analyzed?, :analyzed
      alias_method :include_in_all?, :include_in_all

      private :analyzed, :include_in_all
    end

    def self.fields
      [
        Field.new(:need_id, "long", false, false),
        Field.new(:role, "string", true, true),
        Field.new(:goal, "string", true, true),
        Field.new(:benefit, "string", true, true),
        Field.new(:organisation_ids, "string", false, false),
        Field.new(:applies_to_all_organisations, "boolean", false, false),
        Field.new(:met_when, "string", true, true),
        Field.new(:legislation, "string", false, false),
        Field.new(:other_evidence, "string", true, true),
      ]
    end

    def initialize(need)
      @need = need
    end

    def need_id
      @need.need_id
    end

    def present
      # Populate each field from its corresponding method on the need
      self.class.fields.each_with_object({}) do |field, presented|
        presented[field.name] = @need.send(field.name)
      end
    end
  end
end
