class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy
  # 新規ユーザー登録フォームを表示
  def new
    @user = User.new  # 空の `User` オブジェクトを作成し、フォームに渡す
  end

  # サインアップページを表示（特定の処理はなし）
  def signup
  end

  def index
    @users = User.paginate(page: params[:page])
  end

  # ユーザープロフィールページを表示
  def show
    @user = User.find(params[:id])  # `id` に対応する `User` をデータベースから取得
  end

  # 新規ユーザーを作成（サインアップ処理）
  def create
    @user = User.new(user_params)  # フォームから送られたデータを使って `User` オブジェクトを作成
    if @user.save  # ユーザーの保存に成功した場合
      reset_session  # セッションをリセット（セキュリティ対策）
      log_in @user  # ユーザーをログイン状態にする
      flash[:success] = "Welcome to the Sample App!"  # フラッシュメッセージをセット
      redirect_to @user  # ユーザープロフィールページへリダイレクト
    else  # 保存に失敗した場合
      render 'new', status: :unprocessable_entity  # `new` テンプレートを再表示（エラーメッセージ付き）
    end
  end

  # ユーザー編集ページを表示
  def edit
    @user = User.find(params[:id])  # `id` に対応する `User` を取得
  end

  # ユーザー情報を更新
  def update
    @user = User.find(params[:id])  # `id` に対応する `User` を取得
    if @user.update(user_params)  # フォームから送られたデータで `User` を更新
      flash[:success] = "Profile updated"  # 更新成功のフラッシュメッセージ
      redirect_to @user  # ユーザープロフィールページへリダイレクト
    else  # 更新に失敗した場合
      render 'edit', status: :unprocessable_entity  # `edit` テンプレートを再表示（エラーメッセージ付き）
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url, status: :see_other
  end


  private

    # セキュリティのため、許可されたパラメータのみを取得
    def user_params
      params.require(:user).permit(:name, :email, :password,
                                   :password_confirmation)
    end
    # beforeフィルタ
    # ログイン済みユーザーかどうか確認
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please log in."
        redirect_to login_url, status: :see_other
      end
    end

    # 正しいユーザーかどうか確認
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url, status: :see_other) unless current_user?(@user)
    end
      
      # 管理者かどうか確認
    def admin_user
      redirect_to(root_url, status: :see_other) unless current_user.admin?
    end

end
