class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text, type: String
  field :need_id, type: Integer
  field :author, type: Hash
  field :revision, type: String

  default_scope order_by([:created_at, :desc])

  def save
    need = Need.find(need_id)
    self.revision = need.revisions.first.id
    super
  end
end
