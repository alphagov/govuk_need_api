class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text, type: String
  field :need_id, type: Integer
  field :author, type: Hash
  field :revision, type: String

  default_scope -> { order_by(:created_at.desc) }

  validates_presence_of :text, :need_id, :author
  validate :validate_need_id

  def save
    need = Need.where(need_id: need_id).first
    self.revision = need.revisions.first.id if need
    super
  end

private

  def validate_need_id
    need = Need.where(need_id: need_id).first
    errors.add(:need_id, "A note must have a valid need_id") if need.nil?
  end
end
