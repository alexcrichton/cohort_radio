require 'spec_helper'

describe QueueItem do
  let(:playlist) { Playlist.new }

  before :each do
    subject.playlist = playlist
  end

  context "#enqueue!" do
    let(:user1) { User.new :token => SecureRandom.hex(10) }
    let(:user2) { User.new :token => SecureRandom.hex(10) }
    let(:user3) { User.new :token => SecureRandom.hex(10) }

    before :each do
      subject.stub(:save!)
      subject.user = user1
    end

    it "can be enqueued with no previous items" do
      subject.enqueue!
      subject.priority.should_not be_nil
    end

    it "is placed at the back of the queue always" do
      playlist.queue_items << QueueItem.new(:priority => 0, :user => user1)
      subject.enqueue!
      subject.priority.should > 0

      playlist.queue_items << QueueItem.new(:priority => 2, :user => user1)
      subject.enqueue!
      subject.priority.should > 2
    end

    it "is placed at the back of the queue if another user is first" do
      playlist.queue_items << QueueItem.new(:priority => 0, :user => user2)
      subject.enqueue!
      subject.priority.should > 0
    end

    it "is placed before blocks of other users" do
      playlist.queue_items << QueueItem.new(:priority => 0, :user => user2)
      playlist.queue_items << QueueItem.new(:priority => 2, :user => user2)
      subject.enqueue!
      subject.priority.should > 0
      subject.priority.should < 2
    end

    it "is placed before blocks of other users with others mixed in" do
      playlist.queue_items << QueueItem.new(:priority => 0, :user => user2)
      playlist.queue_items << QueueItem.new(:priority => 1, :user => user3)
      playlist.queue_items << QueueItem.new(:priority => 2, :user => user2)
      subject.enqueue!
      subject.priority.should > 1
      subject.priority.should < 2
    end

    it "is never queued before the same user" do
      playlist.queue_items << QueueItem.new(:priority => 0, :user => user2)
      playlist.queue_items << QueueItem.new(:priority => 2, :user => user1)
      subject.enqueue!
      subject.priority.should > 2
    end

    it "works with multiple users in play" do
      playlist.queue_items << QueueItem.new(:priority => 0, :user => user2)
      playlist.queue_items << QueueItem.new(:priority => 1, :user => user1)
      playlist.queue_items << QueueItem.new(:priority => 2, :user => user2)
      subject.enqueue!
      subject.priority.should > 2

      playlist.queue_items << QueueItem.new(:priority => 3, :user => user1)
      subject.enqueue!
      subject.priority.should > 3

      playlist.queue_items << QueueItem.new(:priority => 4, :user => user3)
      subject.enqueue!
      subject.priority.should > 4

      playlist.queue_items << QueueItem.new(:priority => 6, :user => user2)
      playlist.queue_items << QueueItem.new(:priority => 7, :user => user3)
      subject.enqueue!
      subject.priority.should < 7
      subject.priority.should > 6
    end
  end
end
