# frozen_string_literal: true

require "rails_helper"

describe PasswordsController do
  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
    APP_CONFIG["email"] = {
      "name"     => "Portus",
      "from"     => "portus@example.com",
      "reply_to" => "noreply@example.com"
    }

    @user = create(:admin)
    @raw  = @user.send_reset_password_instructions
  end

  it "updates the user's password on success" do
    put :update, "user" => {
      "reset_password_token"  => @raw,
      "password"              => "12341234",
      "password_confirmation" => "12341234"
    }

    expect(response).to redirect_to root_url
    @user.reload
    expect(@user.valid_password?("12341234")).to be true
  end

  it "does nothing if the user's password does not match confirm" do
    put :update, "user" => {
      "reset_password_token"  => @raw,
      "password"              => "12341234",
      "password_confirmation" => "12341234asdasda"
    }

    expect(response.status).to eq 302
    @user.reload
    expect(@user.valid_password?("12341234")).to be false
  end

  it "redirects on socket error and such" do
    allow(User).to receive(:send_reset_password_instructions) { raise SocketError, "error" }
    post :create, "user" => { "email" => @user.email }
    expect(response.status).to eq 302
  end

  describe "LDAP support is enabled" do
    before do
      APP_CONFIG["ldap"] = { "enabled" => true }
    end

    it "redirects the user when trying to reach :new" do
      get :new
      expect(response).to redirect_to new_user_session_path
    end

    it "redirects the user when trying to :create" do
      post :create, "user" => { "email" => @user.email }
      expect(response).to redirect_to new_user_session_path
    end
  end
end
