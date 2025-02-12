class User < ApplicationRecord

  # ユーザーは複数のマイクロポストを持ち、ユーザー削除時にマイクロポストも削除される
  has_many :microposts, dependent: :destroy
  
  # フォロー関係のアソシエーション
  has_many :active_relationships, class_name:  "Relationship",  # Relationship モデルを使用
                                  foreign_key: "follower_id",    # フォロワー側の ID を外部キーに指定
                                  dependent:   :destroy          # ユーザー削除時にフォロー関係も削除
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  has_many :following, through: :active_relationships, source: :followed  # フォローしているユーザー一覧
  has_many :followers, through: :passive_relationships, source: :follower

  # 仮想の属性（DBには保存しない）を定義
  attr_accessor :remember_token, :activation_token, :reset_token
  
  # コールバック
  before_save   :downcase_email    # 保存前にメールアドレスを小文字化
  before_create :create_activation_digest  # 作成時にアカウント有効化トークンを生成

  # バリデーション（入力チェック）
  validates :name, presence: true, length: { maximum: 50 }  # 名前は必須かつ最大50文字
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },  # メールアドレスも必須
                    format: { with: VALID_EMAIL_REGEX },  # 正規表現で形式をチェック
                    uniqueness: true  # 重複を禁止
  has_secure_password  # パスワードのハッシュ化と認証機能を提供
  validates :password, presence: true, length: { minimum: 8 }, allow_nil: true  # 空のパスワードは許可（編集時用）

  # クラスメソッド（self. 省略可能）

  # 渡された文字列のハッシュ値を返す（パスワードの暗号化）
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを生成する（ユーザー認証用）
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # ユーザーのログイン状態を記憶する（永続セッション）
  def remember
    self.remember_token = User.new_token  # 新しいトークンを生成
    update_attribute(:remember_digest, User.digest(remember_token))  # ハッシュ化してDBに保存
    remember_digest  # トークンのハッシュ値を返す
  end

  # セッションハイジャック防止のためにセッショントークンを返す
  def session_token
    remember_digest || remember  # 既存の remember_digest があればそれを使用、なければ新たに記憶
  end

  # 渡されたトークンがダイジェストと一致すれば true を返す（汎用認証）
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")  # `remember_digest` や `activation_digest` などを取得
    return false if digest.nil?  # ダイジェストがない場合は認証失敗
    BCrypt::Password.new(digest).is_password?(token)  # ハッシュ値を復元して比較
  end

  # ユーザーのログイン情報を破棄する（永続セッションを解除）
  def forget
    update_attribute(:remember_digest, nil)
  end

  # アカウントを有効化する
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)  # 有効化状態を更新
  end

  # 有効化用のメールを送信する
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # パスワードリセット用のトークンを作成し、データベースに保存
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # パスワードリセットのメールを送信する
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # パスワードリセットの期限切れをチェックする（2時間以内でなければ無効）
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # ユーザーのステータスフィードを返す
  def feed
    following_ids = "SELECT followed_id FROM relationships
                     WHERE  follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
             .includes(:user, image_attachment: :blob)
  end

  # 他のユーザーをフォローする
  def follow(other_user)
    following << other_user unless self == other_user  # 自分自身はフォロー不可
  end

  # 他のユーザーのフォローを解除する
  def unfollow(other_user)
    following.delete(other_user)
  end

  # 指定したユーザーをフォローしているか確認
  def following?(other_user)
    following.include?(other_user)
  end

  private

    # メールアドレスをすべて小文字にする（保存前の前処理）
    def downcase_email
      email.downcase!
    end

    # アカウント有効化用のトークンとダイジェストを作成
    def create_activation_digest
      self.activation_token  = User.new_token  # ランダムなトークンを生成
      self.activation_digest = User.digest(activation_token)  # ハッシュ化して保存
    end
end
