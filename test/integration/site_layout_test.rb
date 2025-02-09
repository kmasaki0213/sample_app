require "test_helper"

class SiteLayoutTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)  # `users.yml` の `michael` ユーザーを取得
  end

  test "layout links" do
    get root_path    # ルートページ（ホーム）にアクセス
    assert_template 'static_pages/home'    # 'static_pages/home' テンプレートが描画されているか確認
    assert_select "a[href=?]", root_path, count: 2    # ルートパスへのリンクが2つあることを確認（例: ロゴ、ホームリンク）
    assert_select "a[href=?]", help_path    # "Help" ページへのリンクがあることを確認
    assert_select "a[href=?]", about_path    # "About" ページへのリンクがあることを確認
    assert_select "a[href=?]", contact_path    # "Contact" ページへのリンクがあることを確認
    assert_select "a[href=?]", login_path   # "Contact" ページへのリンクがあることを確認
    assert_select "a[href=?]", signup_path   # "Contact" ページへのリンクがあることを確認

    get contact_path    # "Contact" ページ（/contact）にアクセス
    assert_select "title", full_title("Contact")    # `<title>` が "Contact | Ruby on Rails Tutorial" になっているか確認

    get signup_path    # "Sign up" ページ（/signup）にアクセス
    assert_select "title", full_title("Sign up")    # `<title>` が "Sign up | Ruby on Rails Tutorial" になっているか確認

    log_in_as(@user)
    get root_path
    assert_select "a[href=?]", users_path   # "Contact" ページへのリンクがあることを確認
    assert_select "a[href=?]", user_path(@user)   # "Contact" ページへのリンクがあることを確認
    assert_select "a[href=?]", edit_user_path(@user)  # "Contact" ページへのリンクがあることを確認
    assert_select "a[href=?]", logout_path  # "Contact" ページへのリンクがあることを確認


  end
end
