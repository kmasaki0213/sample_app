require "test_helper"  # Railsのテスト環境をセットアップ

class SessionsHelperTest < ActionView::TestCase

  # テストのセットアップ
  def setup
    @user = users(:michael)  # `users.yml` から `michael` ユーザーを取得
    remember(@user)  # ユーザーの「ログイン状態を保持する」ための remember メソッドを実行
  end

  # セッションが `nil`（ログアウト状態）のときに `current_user` が正しいユーザーを返すか確認
  test "current_user returns right user when session is nil" do
    assert_equal @user, current_user  # `current_user` が `@user` と一致するか
    assert is_logged_in?  # `is_logged_in?` メソッドでログイン状態を確認
  end

  # `remember_digest` が間違っている場合、`current_user` が `nil` を返すことを確認
  test "current_user returns nil when remember digest is wrong" do
    @user.update_attribute(:remember_digest, User.digest(User.new_token))  
    # `remember_digest` を新しい無効なトークンで上書き（正しい `remember_token` とは一致しない）

    assert_nil current_user  # `current_user` が `nil`（ログインできない状態）になっていることを確認
  end
end
