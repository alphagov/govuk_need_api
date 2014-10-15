require_relative '../test_helper'

class DistributedLockTest < ActiveSupport::TestCase
  context "locking" do
    should "prevent a second lock with the same key being acquired concurrently" do
      outer_block_executed = false
      inner_block_executed = false

      DistributedLock.new('testing').lock do
        outer_block_executed = true
        DistributedLock.new('testing', acquire: 0.5).lock do
          inner_block_executed = true
        end
      end

      assert outer_block_executed
      refute inner_block_executed
    end

    should "release the lock immediately after completing" do
      first_block_executed = false
      second_block_executed = false

      DistributedLock.new('testing').lock do
        first_block_executed = true
      end
      DistributedLock.new('testing').lock do
        second_block_executed = true
      end

      assert first_block_executed
      assert second_block_executed
    end
  end
end
