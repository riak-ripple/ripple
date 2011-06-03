require File.expand_path("../../../spec_helper", __FILE__)

describe Ripple::Associations::OneKeyProxy do

  before :each do
    @user    = User.new
    @profile = Profile.new(:color => 'blue')
  end

  describe "User with a key corresponded profile" do
    it "should not have a profile before it is set" do
      @user.profile.should be_nil
    end

    it "should be able to get and set its profile" do
      @user.profile = @profile
      @user.profile.should eq(@profile)
    end

    it "should return the assignment when assigning" do
      rtn = @user.profile = @profile
      rtn.should eq(@profile)
    end

    it "should be able to replace its profile with a new one" do
      @user.profile = @profile
      @user.profile = Profile.new(:color => 'red')
      @user.profile.color.should eq('red')
    end

    it "should be able to build a new profile" do
      Profile.stub(:new).and_return(@profile)
      @user.profile.build.should eq(@profile)
    end

    it "should assign its key to the associated profile when assigning" do
      @user.key     = "foo"
      @user.profile = @profile
      @profile.key.should eq("foo")
    end

    it "should assign its key to the built profile" do
      @user.key = "foo"
      @user.profile.build.key.should eq("foo")
    end

    it "should update the key on the profile when updating it on the user" do
      @user.profile = @profile
      @user.key = "foo"
      @profile.key.should eq("foo")
    end

    it "should not update the key of a previous profile" do
      @profile2 = Profile.new
      @user.profile = @profile
      @user.profile = @profile2
      @user.key = "foo"
      @profile.key.should_not eq("foo")
    end

    it "should not infinitely loop when assigning a user to the profile" do
      @user2 = User.new
      @user.profile = @profile
      @profile.user = @user2
      @profile.key = "foo"
      @user2.key.should eq("foo")
    end

    it "should update the user's key when being updated on the profile" do
      @user.profile = @profile
      @profile.key = "foo"
      @user.key.should eq("foo")
    end

    it "should work properly with custom key methods" do
      @user = Ninja.new(:name => 'Naruto')
      @user.profile = @profile
      @profile.key.should eq("ninja-naruto")
    end
  end

end
