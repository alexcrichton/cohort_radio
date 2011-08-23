require 'spec_helper'

describe Song do
  let(:sample) { File.expand_path('../../fixtures/sample.mp3', __FILE__) }

  before do
    SongUploader.enable_processing = true
  end

  after do
    SongUploader.enable_processing = false
  end

  before :each do
    Resque.stub(:enqueue)
    subject.audio.stub(:encode_to_mp3)
    subject.audio.stub(:store!)
  end

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
    duplicate = Song.new :audio => File.open(sample)
    duplicate.audio.stub(:encode_to_mp3)
    duplicate.audio.stub(:store!)
    duplicate.save!

    subject.audio = File.open(sample)
    subject.should have(1).errors_on(:audio)
  end

  it "doesn't process the audio file during validation" do
    subject.audio.should_not_receive(:encode_to_mp3)
    subject.audio = File.open(sample)
    subject.valid?
  end

  it "processes the audio file upon saving" do
    subject.audio.should_receive(:encode_to_mp3)
    subject.audio = File.open(sample)
    subject.save
  end

end
