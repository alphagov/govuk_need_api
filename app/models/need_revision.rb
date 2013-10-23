class NeedRevision
  include Mongoid::Document
  include Mongoid::Timestamps

  field :action_type, type: String
  field :snapshot, type: Hash
  field :author, type: Hash

  belongs_to :need

  validates :action_type, inclusion: { in: ["create", "update"] }
  validates :snapshot, presence: true

  before_create :filter_snapshot_data

  private
  def filter_snapshot_data
    self.snapshot = snapshot.stringify_keys.except("_id", "need_id")
  end
end
