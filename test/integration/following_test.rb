require "test_helper"

# フォロー機能の統合テストの基本クラス
class Following < ActionDispatch::IntegrationTest

  # すべてのテストで共通するセットアップ処理
  def setup
    @user  = users(:michael)  # テスト用ユーザー `michael` を取得
    @other = users(:archer)   # フォロー対象のユーザー `archer` を取得
    log_in_as(@user)  # `michael` としてログイン
  end
end

# フォロー・フォロワー一覧ページのテスト
class FollowPagesTest < Following

  # （1）フォロー一覧ページの表示を確認
  test "following page" do
    get following_user_path(@user)  # `/users/:id/following` にアクセス
    assert_response :success  # 正常にページが表示されることを確認
    assert_not @user.following.empty?  # `@user` が誰かをフォローしていることを確認
    assert_match @user.following.count.to_s, response.body  # フォロー数が正しく表示されているか確認
    @user.following.each do |user|
      assert_select "a[href=?]", user_path(user)  # 各フォロー対象のプロフィールリンクが存在することを確認
    end
  end

  # （2）フォロワー一覧ページの表示を確認
  test "followers page" do
    get followers_user_path(@user)  # `/users/:id/followers` にアクセス
    assert_response :success  # 正常にページが表示されることを確認
    assert_not @user.followers.empty?  # `@user` にフォロワーがいることを確認
    assert_match @user.followers.count.to_s, response.body  # フォロワー数が正しく表示されているか確認
    @user.followers.each do |user|
      assert_select "a[href=?]", user_path(user)  # 各フォロワーのプロフィールリンクが存在することを確認
    end
  end
end

# フォロー機能のテスト
class FollowTest < Following

  # （3）標準的な方法でユーザーをフォローできることを確認
  test "should follow a user the standard way" do
    assert_difference "@user.following.count", 1 do  # `@user` のフォロー数が1増えることを確認
      post relationships_path, params: { followed_id: @other.id }  # `@other` をフォロー
    end
    assert_redirected_to @other  # フォロー後にフォロー対象のプロフィールページへリダイレクト
  end

  # （4）Hotwire（Turbo Stream）を使ってユーザーをフォローできることを確認
  test "should follow a user with Hotwire" do
    assert_difference "@user.following.count", 1 do  # `@user` のフォロー数が1増えることを確認
      post relationships_path(format: :turbo_stream),
           params: { followed_id: @other.id }  # Turbo Stream 経由で `@other` をフォロー
    end
  end
end

# アンフォロー機能のセットアップクラス
class Unfollow < Following

  # `Following` の `setup` を継承し、さらに `@user` に `@other` をフォローさせる
  def setup
    super  # `Following` の `setup` を実行
    @user.follow(@other)  # `@user` が `@other` をフォロー
    @relationship = @user.active_relationships.find_by(followed_id: @other.id)  # フォロー関係のレコードを取得
  end
end

# アンフォロー機能のテスト
class UnfollowTest < Unfollow

  # （5）標準的な方法でユーザーをアンフォローできることを確認
  test "should unfollow a user the standard way" do
    assert_difference "@user.following.count", -1 do  # `@user` のフォロー数が1減ることを確認
      delete relationship_path(@relationship)  # `@other` とのフォロー関係を削除（アンフォロー）
    end
    assert_response :see_other  # `303 See Other`（リダイレクトの応答コード）を確認
    assert_redirected_to @other  # アンフォロー後に `@other` のプロフィールページへリダイレクト
  end

  # （6）Hotwire（Turbo Stream）を使ってユーザーをアンフォローできることを確認
  test "should unfollow a user with Hotwire" do
    assert_difference "@user.following.count", -1 do  # `@user` のフォロー数が1減ることを確認
      delete relationship_path(@relationship, format: :turbo_stream)  # Turbo Stream 経由で `@other` をアンフォロー
    end
  end
end
