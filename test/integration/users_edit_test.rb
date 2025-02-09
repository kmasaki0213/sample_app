require "test_helper"  # Railsのテスト環境をセットアップ

class UsersEditTest < ActionDispatch::IntegrationTest

  # 各テストの実行前に `@user` をセットアップ（fixtures の `michael` を取得）
  def setup
    @user = users(:michael)  # `users.yml` の `michael` ユーザーを取得
  end

  # 無効な編集を試みた場合のテスト
  test "unsuccessful edit" do
    log_in_as(@user)
    get edit_user_path(@user)  # ユーザー編集ページにアクセス
    assert_template 'users/edit'  # `users/edit` テンプレートが表示されていることを確認

    # 無効な情報（名前なし、無効なメール、パスワード不一致）で更新を試みる
    patch user_path(@user), params: { user: { name:  "",                # 空の名前
                                              email: "foo@invalid",     # 無効なメール
                                              password:              "foo",  # 短すぎるパスワード
                                              password_confirmation: "bar" } }  # パスワード不一致

    assert_select 'div.alert', "The form contains 4 errors."  # エラーメッセージが表示されることを確認
    assert_template 'users/edit'  # 失敗した場合、再度 `users/edit` が描画されることを確認
  end

  # 正常に編集が成功することを確認するテスト
  test "successful edit with friendly forwarding" do
    get edit_user_path(@user)
    log_in_as(@user)
    assert_redirected_to edit_user_url(@user)

    # 有効な情報で更新を試みる
    name  = "Foo Bar"  # 更新後の名前
    email = "foo@bar.com"  # 更新後のメールアドレス
    patch user_path(@user), params: { user: { name:  name,    # 有効な名前
                                              email: email,   # 有効なメール
                                              password:              "",  # 空のパスワード（変更なし）
                                              password_confirmation: "" } }  # 空のパスワード（変更なし）

    assert_not flash.empty?  # `flash` メッセージ（成功通知）が存在することを確認
    assert_redirected_to @user  # 更新後、ユーザーページにリダイレクトされることを確認

    @user.reload  # データベースからユーザー情報を再読み込み
    assert_equal name,  @user.name  # ユーザー名が正しく更新されたことを確認
    assert_equal email, @user.email  # メールアドレスが正しく更新されたことを確認
    assert_nil session[:forwarding_url]
  end
end
