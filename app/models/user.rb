class User < ActiveRecord::Base
  belongs_to :tenant
  has_many :loans
  has_many :loan_requests
  # Are you still using this?
  has_many :user_roles
  has_many :roles, through: :user_roles

  has_secure_password

  validates :first_name, presence: true
  # Maybe don't validate format at all.
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/
  validates :email, presence: true,
                    format: { with: EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :username, length: { minimum: 2, maximum: 32,
                                 too_short: 'must have at least %{count} letters',
                                 too_long: 'must have at most %{count} letters' }
  validates :password, length: { minimum: 6 }, allow_blank: true

  # Burn these with fire.
  before_validation :assign_username
  before_validation :check_last_name

  def is_admin?
    roles.any? { |role| role.name == 'admin' }
  end

  # Consistency is worth it.
  def is_tenant?
    tenant_id != nil
  end

  def is_webmaster?
    roles.any? { |role| role.name == 'webmaster' }
  end

  private

  def assign_username
    self.username ||= first_name
  end

  def check_last_name
    self.last_name ||= ''
  end
end
