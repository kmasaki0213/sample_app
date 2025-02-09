require "test_helper"  # Railsのテスト環境をセットアップ

class UserTest < ActiveSupport::TestCase

  # 各テストの実行前に共通の@userを作成
  def setup
    @user = User.new(name: "Example User", email: "user@example.com",
                     password: "foobarbaz", password_confirmation: "foobarbaz")
  end

  # @user が有効であることを確認
  test "should be valid" do
    puts @user.errors.full_messages
    assert @user.valid?
  end

  # 名前が空白の場合、無効であることを確認
  test "name should be present" do
    @user.name = "     "  # 空白の名前
    assert_not @user.valid?
  end

  # メールアドレスが空白の場合、無効であることを確認
  test "email should be present" do
    @user.email = "     "  # 空白のメールアドレス
    assert_not @user.valid?
  end

  # メールアドレスが長すぎる場合、無効であることを確認
  test "email should not be too long" do
    @user.email = "a" * 244 + "@example.com"  # 255文字以上のメールアドレス
    assert_not @user.valid?
  end

  # 無効なメールアドレスが拒否されることを確認
  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                           foo@bar_baz.com foo@bar+baz.com foo@bar..com]  # 無効なメールアドレスのリスト
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"  # どのメールが失敗したか表示
    end
  end

  # メールアドレスが一意（ユニーク）であることを確認
  test "email addresses should be unique" do
    duplicate_user = @user.dup  # @userの複製を作成
    @user.save  # 元のユーザーを保存
    assert_not duplicate_user.valid?  # 複製したユーザーが無効であることを確認
  end

  # メールアドレスが小文字で保存されることを確認
  test "email addresses should be saved as lowercase" do
    mixed_case_email = "Foo@ExAMPle.CoM"  # 大文字を含むメールアドレス
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email  # データベースに保存された後、小文字になっているか確認
  end

  # パスワードが空白では無効であることを確認
  test "password should be present (nonblank)" do
    @user.password = @user.password_confirmation = " " * 8  # 空白8文字
    assert_not @user.valid?
  end

  # パスワードが最低限の長さ（8文字以上）であることを確認
  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 7  # 7文字（短すぎる）
    assert_not @user.valid?
  end

  test "authenticated? should return false for a user with nil digest" do
    assert_not @user.authenticated?(:remember, '')
  end

end
