require "test_helper"

class UsersShowTest < ActionDispatch::IntegrationTest

  def setup
    @inactive_user  = users(:inactive)  # 未アクティブなユーザー
    @activated_user = users(:archer)    # アクティブなユーザー
  end

  test "should redirect when user not activated" do
    get user_path(@inactive_user)  # 未アクティブユーザーのプロフィールページにアクセス
    assert_response :redirect      # ✅ リダイレクトレスポンスであることを確認（302 Found）
    assert_redirected_to root_url  # ✅ ルートページへリダイレクトされることを確認
  end

  test "should display user when activated" do
    get user_path(@activated_user)  # アクティブユーザーのプロフィールページにアクセス
    assert_response :success        # ✅ 200 OK が返ってくることを確認
    assert_template 'users/show'    # ✅ `users/show` テンプレートが正しく描画されることを確認
  end
end
