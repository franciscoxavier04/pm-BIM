class RecurringMeeting < ApplicationRecord
  include ::Meeting::VirtualStartTime
  belongs_to :project
  belongs_to :author, class_name: "User"

  before_save :update_start_time!

  validates_presence_of :start_time, :title, :frequency, :end_after
  validates_presence_of :end_date, if: -> { end_after_specific_date? }
  validates_numericality_of :iterations, if: -> { end_after_iterations? }

  enum frequency: {
    daily: 0,
    weekly: 1,
    biweekly: 2,
    monthly: 3,
    yearly: 4
  }.freeze, _prefix: true

  enum end_after: {
    specific_date: 0,
    iterations: 1
  }.freeze, _prefix: true

  has_many :meetings, inverse_of: :recurring_meeting

  has_one :template, -> { where(template: true) },
          class_name: "Meeting"

  scope :visible, ->(*args) {
    includes(:project)
      .references(:projects)
      .merge(Project.allowed_to(args.first || User.current, :view_meetings))
  }

  # Keep location and duration as a virtual attribute
  # so it can be passed to the template on save
  virtual_attribute :location do
    nil

  end
  virtual_attribute :duration do
    nil
  end

  def human_frequency
    I18n.t("recurring_meeting.frequency.#{frequency}")
  end

  def human_date_of_week
    day_of_the_week = I18n.l(start_time, format: "%A")
    I18n.t("recurring_meeting.frequency.every_weekday", day_of_the_week:)
  end

  def schedule
    @schedule ||= begin
      IceCube::Schedule.new(start_time, end_time: end_date).tap do |s|
        s.add_recurrence_rule count_rule(frequency_rule)
      end
    end
  end

  def scheduled_occurrences(limit:)
    schedule.next_occurrences(limit, Time.current)
  end

  def remaining_occurrences
    if end_date.present?
      schedule.occurrences_between(Time.current, end_date)
    else
      schedule.remaining_occurrences(Time.current)
    end
  end

  def instances(upcoming: true)
    direction = upcoming ? :upcoming : :past

    meetings
      .not_templated
      .public_send(direction)
      .order(start_time: :asc)
  end

  private

  def frequency_rule
    IceCube::Rule.public_send(frequency)
  end

  def count_rule(rule)
    if end_after_iterations?
      rule.count(iterations)
    else
      rule
    end
  end
end
