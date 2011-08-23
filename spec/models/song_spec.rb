require 'spec_helper'

describe Song do
  let(:sample) { File.expand_path('../../fixtures/sample.mp3', __FILE__) }

  it "is just invalid if no file is provided" do
    subject.save
    subject.should_not be_valid
  end

  it "is valid with audio provided" do
    subject.audio = File.open(sample)
    subject.should have(:no).errors
  end

  it "creates artist/album pairs if they don't exist" do
    subject.audio = File.open(sample)
    subject.save
    subject.album.should be_persisted
    subject.artist.should be_persisted
  end

  it "doesn't allow duplicate songs" do
    duplicate = Song.create! :audio => File.open(sample)
    subject.audio = File.open(sample)
    subject.should have(1).errors_on(:audio)
  end

end
