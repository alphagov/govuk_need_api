class NeedRevision
  include Mongoid::Document
  include Mongoid::Timestamps

  field :action_type, type: String
  field :snapshot, type: Hash
  field :author, type: Hash

  default_scope -> { order_by(:created_at.desc) }

  belongs_to :need, inverse_of: :revisions
  index(need_id: 1, created_at: -1)

  validates :action_type, inclusion: { in: %w(create update close reopen) }
  validates :snapshot, presence: true

  before_create :filter_snapshot_data

private

  def filter_snapshot_data
    self.snapshot = filter_internal_attributes(snapshot.stringify_keys)
  end

  def filter_internal_attributes(hash)
    hash.stringify_keys.except("_id", "need_id").tap do |new_hash|
      new_hash.each { |key, value| new_hash[key] = filter_internal_attributes(value) if value.is_a?(Hash) }
    end
  end
end
