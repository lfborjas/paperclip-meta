require 'spec_helper'

describe "Geometry saver plugin" do
  before(:each) do
    small_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'small.png')
    big_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'big.jpg')
    exif_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'exif.jpg')
    geo_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'geo.jpg')
    not_path = File.join(File.dirname(__FILE__), '..', 'fixtures', 'big.zip')
    @big_image = File.open(big_path)
    @small_image = File.open(small_path)
    @exif_image = File.open exif_path
    @geo_image = File.open geo_path
    @exif_date = DateTime.strptime "2000:10:26 16:46:51", '%Y:%m:%d %H:%M:%S'
    @big_size = Paperclip::Geometry.from_file(big_path)
    @small_size = Paperclip::Geometry.from_file(small_path)
    @not_image = File.open(not_path)
  end

  it "saves gps info for the image" do
    img = Image.new
    img.small_image = @geo_image
    img.save!

    img.small_image.latitude.should ==(40.5736666666667)
    img.small_image.longitude.should == (-73.9836666666667)


  end

  it "saves the original date when it was taken" do
    img = Image.new
    img.small_image = @exif_image
    img.save!

    img.reload

    img.small_image.date_taken.to_s.should eq(@exif_date.to_s)
  end

  it "saves image geometry for original image" do
    img = Image.new
    img.small_image = @small_image
    img.save!

    img.reload # Ensure that updates really saved to db

    img.small_image.width eq(@small_size.width)
    img.small_image.height eq(@small_size.height)
  end

  it "saves geometry for styles" do
    img = Image.new
    img.small_image = @small_image
    img.big_image = @big_image
    img.save!

    img.big_image.width(:small).should == 100
    img.big_image.height(:small).should == 100
  end

  it "clears geometry fields when image is destroyed" do
    img = Image.new
    img.small_image = @small_image
    img.big_image = @big_image
    img.save!

    img.big_image.width(:small).should == 100

    img.big_image = nil
    img.save!

    img.big_image.width(:small).should be_nil
  end

  it "does not fails when file is not an image" do
    img = Image.new
    img.small_image = @not_image
    lambda { img.save! }.should_not raise_error
    img.small_image.width(:small).should be_nil
  end
end
