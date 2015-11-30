module Search
  class IndexConfig
    def initialize(index_client, index_name, type, indexable_class)
      @client = index_client
      @index_name = index_name
      @type = type
      @indexable_class = indexable_class
    end

    def create_index
      @client.create(index: @index_name, body: { "settings" => index_settings })
    end

    def delete_index
      @client.delete(index: @index_name)
    end

    def index_exists?
      @client.exists(index: @index_name)
    end

    def put_mappings
      @client.put_mapping(
        index: @index_name,
        type: @type,
        body: {
          @type => {
            "properties" => mapping_properties
          }
        }
      )
    end

  private
    def mapping_properties
      @indexable_class.fields.each_with_object({}) do |field, properties|
        properties[field.name.to_s] = {
          "type" => field.type,
          "index" => (field.analyzed? ? "analyzed" : "not_analyzed"),
          "include_in_all" => field.include_in_all?
        }
      end
    end

    def index_settings
      {
        "analysis" => {
          "analyzer" => {
            "default" => { "type" => "snowball" }
          }
        }
      }
    end
  end
end
