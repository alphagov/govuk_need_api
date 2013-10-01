class Organisation
  include Mongoid::Document

  field :name, type: String
  field :slug, type: String
  field :_id,  type: String, default: ->{ slug }

  validates :name, :slug, presence: true
  validates :slug, uniqueness: { case_sensitive: false }
end
