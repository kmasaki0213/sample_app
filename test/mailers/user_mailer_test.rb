require "test_helper"

class UserMailerTest < ActionMailer::TestCase

  def setup
    @user = users(:michael)  # `users.yml` の `michael` ユーザーを取得
  end

  test "account_activation" do
    @user.activation_token = User.new_token
    mail = UserMailer.account_activation(@user)
    assert_equal "Account activation", mail.subject
    assert_equal [@user.email], mail.to
    assert_equal ["k4masa0213@gmail.com"], mail.from
    assert_match @user.name,               mail.body.encoded
    assert_match @user.activation_token,   mail.body.encoded
    assert_match CGI.escape(@user.email),  mail.body.encoded
  end

  test "password_reset" do
    @user.reset_token = User.new_token
    mail = UserMailer.password_reset(@user)
    assert_equal "Password reset", mail.subject
    assert_equal [@user.email], mail.to
    assert_equal ["k4masa0213@gmail.com"], mail.from
    assert_match @user.reset_token,        mail.body.encoded
    assert_match CGI.escape(@user.email),  mail.body.encoded
  end

end
