class NeedSearchResult < OpenStruct
  def initialize(hash)
    super(hash)
    freeze
  end
end
