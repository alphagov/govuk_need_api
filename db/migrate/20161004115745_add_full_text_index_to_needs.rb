class AddFullTextIndexToNeeds < Mongoid::Migration
  def self.up
    session = Mongoid::Sessions.default
    session.with(database: :admin).command({ setParameter: 1, textSearchEnabled: true })
  end
end
