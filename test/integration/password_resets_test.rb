require "test_helper"

# パスワードリセット関連の統合テストクラス
class PasswordResets < ActionDispatch::IntegrationTest

  # 各テスト前にメールの送信履歴をクリアする
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:michael)
  end
end

# パスワードリセットのフォームに関するテスト
class ForgotPasswordFormTest < PasswordResets

  # パスワードリセットページのパスが正しいかのテスト
  test "password reset path" do
    get new_password_reset_path  # リセットページにGETリクエスト
    assert_template 'password_resets/new'  # リセットページのテンプレートが正しいか確認
    assert_select 'input[name=?]', 'password_reset[email]'  # フォームに正しいname属性があるか確認
  end

  # 無効なメールアドレスでリセットフォームを送信したときのテスト
  test "reset path with invalid email" do
    post password_resets_path, params: { password_reset: { email: "" } }  # 無効なメールアドレスでPOSTリクエスト
    assert_response :unprocessable_entity  # 期待通りエラーが発生しているか
    assert_not flash.empty?  # フラッシュメッセージが空でないことを確認
    assert_template 'password_resets/new'  # リセットフォームのページが再表示されていることを確認
  end
end

# パスワードリセットフォームを設定するための基盤クラス
class PasswordResetForm < PasswordResets

  def setup
    super
    @user = users(:michael)  # テスト用の有効なユーザー（users.yml）を取得
    post password_resets_path, params: { password_reset: { email: @user.email } }  # パスワードリセットのリクエストを送信
    @reset_user = assigns(:user)  # リセットされたユーザーのインスタンスを取得
  end
end

# パスワードリセットフォームに関する詳細なテスト
class PasswordFormTest < PasswordResetForm

  # 正しいメールアドレスでリセットした場合のテスト
  test "reset with valid email" do
    assert_not_equal @user.reset_digest, @reset_user.reset_digest  # リセット前のreset_digestとリセット後が異なることを確認
    assert_equal 1, ActionMailer::Base.deliveries.size  # メールが1通送信されたか確認
    assert_not flash.empty?  # フラッシュメッセージが空でないことを確認
    assert_redirected_to root_url  # ルートURLにリダイレクトされることを確認
  end

  # 間違ったメールアドレスでリセットした場合のテスト
  test "reset with wrong email" do
    get edit_password_reset_path(@reset_user.reset_token, email: "")  # 間違ったメールアドレスでリセットリンクにアクセス
    assert_redirected_to root_url  # ルートURLにリダイレクトされることを確認
  end

  # 非アクティブなユーザーでリセットした場合のテスト
  test "reset with inactive user" do
    @reset_user.toggle!(:activated)  # ユーザーを非アクティブにする
    get edit_password_reset_path(@reset_user.reset_token, email: @reset_user.email)  # 非アクティブユーザーでリセットリンクにアクセス
    assert_redirected_to root_url  # ルートURLにリダイレクトされることを確認
  end

  # 正しいメールアドレスだが間違ったトークンでリセットした場合のテスト
  test "reset with right email but wrong token" do
    get edit_password_reset_path('wrong token', email: @reset_user.email)  # 間違ったトークンでリセットリンクにアクセス
    assert_redirected_to root_url  # ルートURLにリダイレクトされることを確認
  end

  # 正しいメールアドレスと正しいトークンでリセットした場合のテスト
  test "reset with right email and right token" do
    get edit_password_reset_path(@reset_user.reset_token, email: @reset_user.email)  # 正しいメールアドレスとトークンでリセットリンクにアクセス
    assert_template 'password_resets/edit'  # パスワードリセットフォームのテンプレートが表示されることを確認
    assert_select "input[name=email][type=hidden][value=?]", @reset_user.email  # 隠しフィールドにメールアドレスが設定されていることを確認
  end
end

# パスワード更新に関するテスト
class PasswordUpdateTest < PasswordResetForm

  # 無効なパスワードと確認用パスワードで更新した場合のテスト
  test "update with invalid password and confirmation" do
    patch password_reset_path(@reset_user.reset_token),
          params: { email: @reset_user.email,
                    user: { password:              "foobaz",
                            password_confirmation: "barquux" } }  # 無効なパスワードで更新リクエストを送信
    assert_select 'div#error_explanation'  # エラーが表示されることを確認
  end

  # 空のパスワードで更新した場合のテスト
  test "update with empty password" do
    patch password_reset_path(@reset_user.reset_token),
          params: { email: @reset_user.email,
                    user: { password:              "",
                            password_confirmation: "" } }  # 空のパスワードで更新リクエストを送信
    assert_select 'div#error_explanation'  # エラーが表示されることを確認
  end

  # 正しいパスワードと確認用パスワードで更新した場合のテスト
  test "update with valid password and confirmation" do
    patch password_reset_path(@reset_user.reset_token),
          params: { email: @reset_user.email,
                    user: { password:              "foobazboo",
                            password_confirmation: "foobazboo" } }  # 有効なパスワードで更新リクエストを送信
    assert is_logged_in?  # ログイン状態であることを確認
    assert_not flash.empty?  # フラッシュメッセージが空でないことを確認
    assert_redirected_to @reset_user  # 更新されたユーザーの詳細ページにリダイレクトされることを確認
    assert_nil @user.reload.reset_digest  # リセット後にreset_digestがnilになっているか確認
  end
end

class ExpiredToken < PasswordResets

  def setup
    super
    # パスワードリセットのトークンを作成する
    post password_resets_path,
         params: { password_reset: { email: @user.email } }
    @reset_user = assigns(:user)
    # トークンを手動で失効させる
    @reset_user.update_attribute(:reset_sent_at, 3.hours.ago)
    # ユーザーのパスワードの更新を試みる
    patch password_reset_path(@reset_user.reset_token),
          params: { email: @reset_user.email,
                    user: { password:              "foobar",
                            password_confirmation: "foobar" } }
  end
end

class ExpiredTokenTest < ExpiredToken

  test "should redirect to the password-reset page" do
    assert_redirected_to new_password_reset_url
  end

  test "should include the word 'expired' on the password-reset page" do
    follow_redirect!  # リダイレクト先のページに移動する
    assert_match /expired/i, response.body  # ページの内容に "expired"（期限切れ）という単語が含まれているか確認
  end  
end