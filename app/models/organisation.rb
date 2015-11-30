class Organisation
  include Mongoid::Document

  field :_id, type: String, default: -> { slug }

  field :name, type: String
  field :slug, type: String
  field :content_id, type: String
  field :govuk_status, type: String, default: ""
  field :abbreviation, type: String, default: ""
  field :parent_ids, type: Array, default: []
  field :child_ids, type: Array, default: []

  index name: 1

  validates :name, :slug, presence: true
  validates :slug, uniqueness: { case_sensitive: false }

  scope :in_name_order, -> { order_by(:name.asc) }

  def as_json
    attributes.
      slice("name", "govuk_status", "abbreviation", "parent_ids", "child_ids").
      tap { |json| json["id"] = self.slug }
  end
end
