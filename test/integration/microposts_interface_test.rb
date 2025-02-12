require "test_helper"

class MicropostsInterface < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    log_in_as(@user)
  end
end

class MicropostsInterfaceTest < MicropostsInterface

  test "should paginate microposts" do
    get root_path
    assert_select 'div.pagination'
  end

  test "should show errors but not create micropost on invalid submission" do
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: "" } }
    end
    assert_select 'div#error_explanation'
    assert_select 'a[href=?]', '/?page=2'  # 正しいページネーションリンク
  end

  test "should create a micropost on valid submission" do
    content = "This micropost really ties the room together"
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost: { content: content } }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
  end

  test "should have micropost delete links on own profile page" do
    get user_path(@user)
    assert_select 'a', text: 'delete'
  end

  test "should be able to delete own micropost" do
    first_micropost = @user.microposts.paginate(page: 1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end
  end

  test "should not have delete links on other user's profile page" do
    get user_path(users(:archer))
    assert_select 'a', { text: 'delete', count: 0 }
  end
end

class MicropostSidebarTest < MicropostsInterface

  # （1）正しいマイクロポストの投稿数が表示されることを確認
  test "should display the right micropost count" do
    get root_path
    assert_match "#{@user.microposts.count} microposts", response.body  # ✅ @user の投稿数が表示されることを確認
  end

  # （2）マイクロポストが 0 件の場合の表示を確認
  test "should use proper pluralization for zero microposts" do
    log_in_as(users(:malory))  # `malory` は投稿を持たないユーザー
    get root_path
    assert_match "0 microposts", response.body  # ✅ "0 microposts" と表示されることを確認
  end

  # （3）マイクロポストが 1 件の場合の表示を確認
  test "should use proper pluralization for one micropost" do
    log_in_as(users(:lana))  # `lana` は1つだけ投稿を持つユーザー
    get root_path
    assert_match "1 micropost", response.body  # ✅ "1 micropost"（単数形）と表示されることを確認
  end
end

class ImageUploadTest < MicropostsInterface

  # （1）画像アップロード用のファイル入力フィールドがあるか確認
  test "should have a file input field for images" do
    get root_path  # ホームページにアクセス
    assert_select 'input[type=file]'  # ✅ 画像アップロード用の input タグ（type="file"）が存在することを確認
  end

  # （2）画像を添付してマイクロポストを投稿できるか確認
  test "should be able to attach an image" do
    cont = "This micropost really ties the room together."  # 投稿の内容
    img  = fixture_file_upload('kitten.jpg', 'image/jpeg')  # ✅ `kitten.jpg` をアップロードするテストデータとして準備

    # 画像付きのマイクロポストを投稿
    post microposts_path, params: { micropost: { content: cont, image: img } }

    # ✅ 投稿されたマイクロポストがデータベースに保存され、画像が添付されているか確認
    assert assigns(:micropost).image.attached?  
  end
end
