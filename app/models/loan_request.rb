class LoanRequest < ActiveRecord::Base
  belongs_to :user
  default_scope { order('updated_at DESC') }
  scope :status, -> (status) { where status: status }

  has_many :loan_request_categories
  has_many :categories, through: :loan_request_categories
  has_many :loans
  has_attached_file :image, styles: { thumb: '100x100>', main: '300x300>' },
    default_url: 'missing.png'

  validate :request_date
  validate :begin_date
  validate :end_date
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/
  validates :user_id, presence: true
  validates :title, presence: true
  validates :blurb, presence: true
  validates :description, presence: true
  validates :borrowing_amount, presence: true,
    numericality: { only_integer: true }
  validates :amount_funded, presence: true
  validates :requested_by_date, presence: true
  validates :payments_begin_date, presence: true
  validates :payments_end_date, presence: true
  validates :status, presence: true

  # Make as much private as possible, including this.
  def ensure_request_date_not_in_past
    if request_date_is_in_past?
      errors.add(:requested_by_date, 'cannot be in the past')
    end
  end

  # Basically always extract compound conditionals.
  # Make them private too.
  def request_date_is_in_past?
    requested_by_date.present? && requested_by_date < Date.today
  end


  # Fix name, extract compound conditional.
  def begin_date
    if payments_begin_date.present? &&
        payments_begin_date < requested_by_date.months_since(1)
      errors.add(:payments_begin_date, 'must be at least one month from today')
    end
  end

  def end_date
    if payments_end_date.present? &&
        payments_end_date < requested_by_date.months_since(3)
      errors.add(:payments_end_date, 'must be at least three months from today')
    end
  end

  # You can use two numbers in code: 0 and 1.
  # The rest should be defined as constants.
  def loan_term
    ((payments_end_date - payments_begin_date) / 2_592_000).round
  end

  def repayment_rate
    borrowing_amount / loan_term
  end

  def remaining_amount
    borrowing_amount - amount_funded
  end

  def category_names
    categories.map(&:name)
  end

  # We are using "funded" to mean two different things.
  # This is a *lack* of consistency.
  def is_funded?
    amount_funded == borrowing_amount
  end

  def mark_as_funded!
    self.status = "closed"
    save!
  end
end
