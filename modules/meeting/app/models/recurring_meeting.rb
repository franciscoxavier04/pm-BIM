class RecurringMeeting < ApplicationRecord
  include ::Meeting::VirtualStartTime
  belongs_to :project
  belongs_to :author, class_name: "User"

  before_save :update_start_time!

  validates_presence_of :start_time, :title, :frequency, :end_after
  validates_presence_of :end_date, if: -> { end_after_specific_date? }
  validates_numericality_of :iterations, if: -> { end_after_iterations? }
  validates :end_date,
            date: { after: :start_date },
            if: -> { end_after_specific_date? }

  enum frequency: {
    daily: 0,
    working_days: 1,
    weekly: 2
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

  def human_day_of_week
    I18n.t("recurring_meeting.frequency.every_weekday", day_of_the_week: weekday)
  end

  def weekday
    I18n.l(start_time, format: "%A")
  end

  def date
    start_time.day.ordinalize
  end

  def schedule
    @schedule ||= IceCube::Schedule.new(start_date.to_time(:utc), end_time: end_date).tap do |s|
      s.add_recurrence_rule count_rule(frequency_rule)
      exclude_non_working_days(s) if frequency_working_days?
    end
  end

  def schedule_in_words # rubocop:disable Metrics/AbcSize
    base = case frequency
           when "daily"
             interval == 1 ? human_frequency : I18n.t("recurring_meeting.in_words.daily_interval", interval: interval.ordinalize)
           when "working_days"
             if interval == 1
               I18n.t("recurring_meeting.in_words.working_days")
             else
               I18n.t("recurring_meeting.in_words.working_days_interval", interval: interval.ordinalize)
             end
           when "weekly"
             if interval == 1
               I18n.t("recurring_meeting.in_words.weekly", weekday:)
             else
               I18n.t("recurring_meeting.in_words.weekly_interval", interval: interval.ordinalize, weekday:)
             end
           end

    I18n.t("recurring_meeting.in_words.full", base:, time: format_time(start_time, include_date: false), end_date:)
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

  def exclude_non_working_days(schedule)
    NonWorkingDay
      .where(date: start_date...)
      .pluck(:date)
      .each do |date|
      schedule.add_exception_time(date.to_time(:utc))
    end
  end

  def frequency_rule
    case frequency
    when "daily"
      IceCube::Rule.daily(interval)
    when "working_days"
      IceCube::Rule
        .weekly(interval)
        .day(*Setting.working_day_names)
    when "weekly"
      IceCube::Rule.weekly(interval)
    else
      raise NotImplementedError
    end
  end

  def count_rule(rule)
    if end_after_iterations?
      rule.count(iterations)
    else
      rule
    end
  end
end
