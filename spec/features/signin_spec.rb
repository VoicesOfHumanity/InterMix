require "rails_helper"

=begin
#describe "the signin process", :type => :feature, :js => true do
describe "the signin process", :type => :feature do
  before :each do
    Rails.logger.info("create participant--------------------")
    @participant = Participant.new(email: 'ffunch234@newciv.org', password: 'test', password_confirmation: 'test')
    @participant.save!
    @participant.confirmed_at = Time.now
    @participant.status = 'active'
    @participant.save!
    #@participant = FactoryGirl.create(:participant)
    Rails.logger.info("create group--------------------")
    @group = Group.new(name: 'Test Group', shortname: 'testg')
    @group.participants << @participant
    @group.save!
    #request.host = "testg.intermix.dev"
    #host! "testg.#{host}"
  end
  

  it "signs me in" do
    Rails.logger.info("testing sign-in process--------------------")
    visit '/participants/sign_in'
    within("#new_participant") do
      fill_in 'participant_email', :with => 'ffunch234@newciv.org'
      fill_in 'participant_password', :with => 'test'
    end
    click_button 'Sign in'
    expect(page).to have_content 'Signed in successfully'
  end
end
=end