require "test_helper"  # Railsのテスト環境をセットアップ

class UsersIndexTest < ActionDispatch::IntegrationTest

  # 各テストの実行前に `@admin`（管理者）と `@non_admin`（一般ユーザー）をセットアップ
  def setup
    @admin     = users(:michael)  # 管理者ユーザー
    @non_admin = users(:archer)   # 一般ユーザー
  end

  # 管理者ユーザーとして「ユーザー一覧ページ」にアクセスした場合のテスト
  test "index as admin including pagination and delete links" do
    log_in_as(@admin)  # 管理者としてログイン
    get users_path  # `GET /users`（ユーザー一覧ページ）にアクセス
    assert_template 'users/index'  # `users/index` テンプレートが表示されることを確認
    assert_select 'div.pagination'  # ページネーションが存在することを確認

    # 1ページ目のユーザーを取得（ページネーション対応）
    first_page_of_users = User.paginate(page: 1)
    first_page_of_users.each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name  # 各ユーザーの詳細ページへのリンクがあることを確認
      unless user == @admin  # 管理者自身には「削除リンク」を表示しない
        assert_select 'a[href=?]', user_path(user), text: 'delete'  # 一般ユーザーには削除リンクが表示されることを確認
      end
    end

    # `delete` リクエストを送り、一般ユーザー（@non_admin）を削除できることを確認
    assert_difference 'User.count', -1 do  # ユーザー数が1減ることを確認
      delete user_path(@non_admin)  # `DELETE /users/:id`（ユーザー削除）
      assert_response :see_other  # HTTP 303 See Other（リダイレクトが発生）
      assert_redirected_to users_url  # ユーザー一覧ページにリダイレクトされることを確認
    end
  end

  # 一般ユーザーとして「ユーザー一覧ページ」にアクセスした場合のテスト
  test "index as non-admin" do
    log_in_as(@non_admin)  # 一般ユーザーとしてログイン
    get users_path  # `GET /users`（ユーザー一覧ページ）にアクセス
    assert_select 'a', text: 'delete', count: 0  # 「削除リンク」が1つも表示されていないことを確認
  end
end
