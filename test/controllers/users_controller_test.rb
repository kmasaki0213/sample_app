require "test_helper"  # Railsのテスト環境をセットアップ

class UsersControllerTest < ActionDispatch::IntegrationTest

  # 各テストの実行前に `@user` をセットアップ（fixtures の `michael` を取得）
  def setup
    @user = users(:michael)  # `users.yml` の `michael` ユーザーを取得
    @other_user = users(:archer)  # `users.yml` の `archer` ユーザーを取得
  end

  # サインアップページが正常に表示されることをテスト
  test "should get signup" do
    get signup_path  # `GET /signup` リクエストを送る
    assert_response :success  # レスポンスが 200 OK であることを確認
  end

  # ログインしていない状態で編集ページにアクセスした場合、ログインページへリダイレクトされることをテスト
  test "should redirect edit when not logged in" do
    get edit_user_path(@user)  # `GET /users/:id/edit` にアクセス（ログインなし）
    assert_not flash.empty?  # `flash` にエラーメッセージが含まれていることを確認
    assert_redirected_to login_url  # ログインページへリダイレクトされることを確認
  end

  # ログインしていない状態でユーザー情報を更新しようとした場合、ログインページへリダイレクトされることをテスト
  test "should redirect update when not logged in" do
    patch user_path(@user), params: { user: { name: @user.name,
                                              email: @user.email } }  # `PATCH /users/:id` にアクセス（ログインなし）
    assert_not flash.empty?  # `flash` にエラーメッセージが含まれていることを確認
    assert_redirected_to login_url  # ログインページへリダイレクトされることを確認
  end

  test "should not allow the admin attribute to be edited via the web" do
    log_in_as(@other_user)  # 他のユーザーでログイン
    assert_not @other_user.admin?  # もともと管理者ではないことを確認
  
    patch user_path(@other_user), params: {
                                    user: { password:              "password",
                                            password_confirmation: "password",
                                            admin: true } }  # `admin: true` を送信して管理者に昇格を試みる
  
    assert_not @other_user.reload.admin?  # データベースをリロードし、`admin` が変更されていないことを確認
  end

  test "should redirect edit when logged in as wrong user" do
    log_in_as(@other_user)
    get edit_user_path(@user)
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should redirect update when logged in as wrong user" do
    log_in_as(@other_user)
    patch user_path(@user), params: { user: { name: @user.name,
                                              email: @user.email } }
    assert flash.empty?
    assert_redirected_to root_url
  end

  test "should redirect index when not logged in" do
    get users_path
    assert_redirected_to login_url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference 'User.count' do
      delete user_path(@user)
    end
    assert_response :see_other
    assert_redirected_to login_url
  end

  test "should redirect destroy when logged in as a non-admin" do
    log_in_as(@other_user)
    assert_no_difference 'User.count' do
      delete user_path(@user)
    end
    assert_response :see_other
    assert_redirected_to root_url
  end
end
