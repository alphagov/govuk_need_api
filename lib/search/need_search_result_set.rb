module Search
  class NeedSearchResultSet
    attr_reader :results, :total_count

    def initialize(results, total_count)
      @results = results
      @total_count = total_count
    end
  end
end
