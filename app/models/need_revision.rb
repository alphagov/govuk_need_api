class NeedRevision
  include Mongoid::Document
  include Mongoid::Timestamps

  field :action_type, type: String
  field :snapshot, type: Hash
  field :author, type: Hash

  default_scope order_by([:created_at, :desc])

  belongs_to :need
  index [[ :need_id, Mongo::ASCENDING ], [ :created_at, Mongo::DESCENDING ]]

  validates :action_type, inclusion: { in: ["create", "update", "close", "reopen"] }
  validates :snapshot, presence: true

  before_create :filter_snapshot_data

  private
  def filter_snapshot_data
    self.snapshot = filter_internal_attributes(snapshot.stringify_keys)
  end

  def filter_internal_attributes(hash)
    hash.stringify_keys.except("_id", "need_id").tap do |hash|
      hash.each { |key, value| hash[key] = filter_internal_attributes(value) if value.is_a?(Hash) }
    end
  end
end
