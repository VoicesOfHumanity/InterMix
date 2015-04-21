require "rails_helper"

describe "Authentication" do

    subject { page }

    describe "Signup page" do
        before { visit '/join' }

        let(:submit) { "Send!" }

        describe "with invalid information" do
          it "should not create a participant" do
            expect { click_button submit }.not_to change(Participant, :count)
          end

          describe "after submission" do
            before { click_button submit }

            it { should have_content('Sign up') }
            it { should have_content('Please enter') }
          end
        end

        describe "with valid information" do
          before do
            fill_in "first_name",   with: "Example"
            fill_in "last_name",    with: "Lastname"
            fill_in "email",        with: "ffunch1@newciv.org"
            fill_in "password",     with: "test12345"
            fill_in "password_confirmation",     with: "test12345"
            fill_in "country_code", with: 'us'
          end

          it "should create a participant" do
            expect { click_button submit }.to change(Participant, :count).by(1)
          end

          #describe "after saving the user" do
            #before { click_button submit }
            #let(:user) { User.find_by(email: 'user@example.com') }

            #it { should have_title(user.first_name) }
            #it { should have_selector('div.flash_success', text: 'Welcome') }
         # end
        end

        it { should have_content('Sign up') }
    end


    describe "Signin page" do 

        before { visit '/participants/sign_in' }

        describe "with invalid information" do
            before { click_button "Sign in" }

            it { should have_content('Sign in') }
            it { should have_content('Invalid email or password.') }
            #it { should have_selector('div.flash_alert', text: "Invalid") }

        end

        describe "with valid information" do
            let(:participant) { FactoryGirl.create(:participant) }
            before do 
                fill_in "email",    with: participant.email
                fill_in "password", with: participant.password
                click_button "Sign in"
            end

            it { should_not have_selector('a', text: 'Sign up')}
            it { should_not have_selector('a', text: 'Sign in')}
            it { should have_selector('a', text: 'Me & My Friends') }
            it { should have_selector('a', text: 'Sign out') }
            it { should have_content('Signed in successfully') }
            #it { should have_selector('div.flash_notice', text: "Signed in successfully.") }

        end

        it { should have_content('Sign in') }
    end
end