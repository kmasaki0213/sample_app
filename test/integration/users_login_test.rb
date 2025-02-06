require "test_helper"  # Railsのテスト環境をセットアップ

class UsersLoginTest < ActionDispatch::IntegrationTest
  # 各テストの実行前に `@user` をセットアップ（fixtures の `michael` を取得）
  def setup
    @user = users(:michael)  # `users.yml` の `michael` ユーザーを取得
  end
end

class InvalidPasswordTest < UsersLoginTest
  # ログインページが正しく表示されるかテスト
  test "login path" do
    get login_path  # ログインページを開く（GETリクエスト）
    assert_template 'sessions/new'  # `sessions/new` テンプレートが表示されていることを確認
  end

  # 正しいメールアドレス + 間違ったパスワードでログインを試みるテスト
  test "login with valid email/invalid password" do
    post login_path, params: { session: { email: @user.email, password: "invalid" } }
    assert_not is_logged_in?  # ログインされていないことを確認
    assert_response :unprocessable_entity  # HTTP 422 Unprocessable Entity（処理できないエンティティ）が返ることを確認
    assert_template 'sessions/new'  # もう一度 `sessions/new` が描画される（ログインページに戻る）
    assert_not flash.empty?  # `flash` にエラーメッセージが入っていることを確認
    get root_path  # 別のページ（ホーム）に移動
    assert flash.empty?  # `flash` がリセットされていることを確認（リダイレクト後に消える）
  end
end

class ValidLogin < UsersLoginTest
  def setup
    super
    # 有効な情報でログインを試みる
    post login_path, params: { session: { email: @user.email, password: 'password' } }
  end
end

# 正しい情報でログインするテスト
class ValidLoginTest < ValidLogin
  test "valid login" do
    assert is_logged_in?  # ログインされていることを確認
    assert_redirected_to @user  # ユーザーのプロフィールページにリダイレクトされることを確認
  end

  # ログイン後のページ遷移やリンクを確認するテスト
  test "redirect after login" do
    follow_redirect!  # 実際にリダイレクトを実行
    assert_template 'users/show'  # `users/show`（プロフィールページ）が表示されていることを確認

    # ナビゲーションリンクの確認（ログイン中の状態）
    assert_select "a[href=?]", login_path, count: 0  # ログインリンクが表示されていないことを確認（ログイン中なので不要）
    assert_select "a[href=?]", logout_path  # ログアウトリンクが表示されていることを確認
    assert_select "a[href=?]", user_path(@user)  # プロフィールページへのリンクが表示されていることを確認
  end
end

class Logout < ValidLogin
  def setup
    super
    delete logout_path  # ログアウトを実行
  end
end

# ログアウトの挙動を確認するテスト
class LogoutTest < Logout
  # 正しくログアウトできているかを確認
  test "successful logout" do
    assert_not is_logged_in?  # ログアウトされていることを確認
    assert_response :see_other  # HTTP 303 See Other（リダイレクトの応答）が返ることを確認
    assert_redirected_to root_url  # ホームページにリダイレクトされることを確認
  end

  # ログアウト後のページ遷移やリンクを確認するテスト
  test "redirect after logout" do
    follow_redirect!  # リダイレクトを実行

    # ナビゲーションリンクの再確認（ログアウト後の状態）
    assert_select "a[href=?]", login_path  # ログインリンクが再び表示されていることを確認
    assert_select "a[href=?]", logout_path, count: 0  # ログアウトリンクが消えていることを確認
    assert_select "a[href=?]", user_path(@user), count: 0  # プロフィールページへのリンクが消えていることを確認
  end
end
