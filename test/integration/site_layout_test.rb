require "test_helper"

class SiteLayoutTest < ActionDispatch::IntegrationTest

  test "layout links" do
    get root_path    # ルートページ（ホーム）にアクセス
    assert_template 'static_pages/home'    # 'static_pages/home' テンプレートが描画されているか確認
    assert_select "a[href=?]", root_path, count: 2    # ルートパスへのリンクが2つあることを確認（例: ロゴ、ホームリンク）
    assert_select "a[href=?]", help_path    # "Help" ページへのリンクがあることを確認
    assert_select "a[href=?]", about_path    # "About" ページへのリンクがあることを確認
    assert_select "a[href=?]", contact_path    # "Contact" ページへのリンクがあることを確認

    get contact_path    # "Contact" ページ（/contact）にアクセス
    assert_select "title", full_title("Contact")    # `<title>` が "Contact | Ruby on Rails Tutorial" になっているか確認

    get signup_path    # "Sign up" ページ（/signup）にアクセス
    assert_select "title", full_title("Sign up")    # `<title>` が "Sign up | Ruby on Rails Tutorial" になっているか確認
  end
end
