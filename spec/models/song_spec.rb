require 'spec_helper'
require 'tempfile'

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
    subject.artist.should be_persisted
  end

  it "doesn't allow duplicate songs and doesn't process audio if invalid" do
    duplicate = Song.new
    duplicate.audio.stub(:encode_to_mp3)
    duplicate.audio.stub(:store!)
    duplicate.audio = File.open(sample)
    duplicate.save!

    subject.audio.should_not_receive(:encode_to_mp3)
    subject.audio = File.open(sample)
    subject.should have(1).errors_on(:audio)
  end

  it "doesn't process the audio file during validation if valid" do
    subject.audio.should_receive(:encode_to_mp3)
    subject.audio = File.open(sample)
    subject.valid?
  end

  it "doesn't save the song if there's a processing error" do
    subject.save

    subject.should_not be_persisted
  end

  context "creating artists/albums" do
    before :each do
      subject.audio.stub(:encode_to_mp3).and_raise(CarrierWave::IntegrityError)
      subject.stub(:audio_integrity_error)
      subject.stub(:audio_processing_error)
      subject.audio = File.open(sample)
    end

    it "creates both" do
      subject.artist_name = 'artist'
      subject.album_name = 'album'
      subject.save

      subject.artist.should be_persisted
      subject.artist.name.should == 'artist'
      subject.album.should be_persisted
      subject.album.name.should == 'album'
    end

    it "creates both when the subject is previously saved" do
      subject.save
      subject.should be_persisted

      subject.artist_name = 'artist'
      subject.album_name = 'album'
      subject.save
      subject.artist.should be_persisted
      subject.artist.name.should == 'artist'
      subject.album.should be_persisted
      subject.album.name.should == 'album'

      subject.artist_name = 'artist2'
      subject.album_name = 'album2'
      subject.save
      subject.artist.should be_persisted
      subject.artist.name.should == 'artist2'
      subject.album.should be_persisted
      subject.album.name.should == 'album2'
    end
  end
end
