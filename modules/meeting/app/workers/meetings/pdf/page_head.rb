module Meetings::PDF
  module PageHead
    def write_page_head
      with_margin(styles.page_heading_margins) do
        pdf.formatted_text([styles.page_heading.merge({ text: meeting_title })])
        pdf.move_down(2)
        write_meeting_subtitle
        pdf.move_down(3)
      end
    end

    def write_meeting_subtitle
      subtitle_font_size = 10
      pdf.formatted_text(
        [
          prawn_badge(badge_text, badge_color, offset: 0, radius: 2),
          { text: " ", size: subtitle_font_size },
          { text: format_date(meeting.start_date), size: subtitle_font_size },
          { text: ", ", size: subtitle_font_size },
          { text: meeting_subtitle_dates, size: subtitle_font_size }
        ]
      )

      # meeting.recurring? ? write_meeting_subtitle_recurring :
    end

    def meeting_subtitle_dates
      format_date(meeting.start_date) +
        ", " +
        format_time(meeting.start_time, include_date: false) +
        " – " +
        format_time(meeting.end_time, include_date: false) +
        " (" +
        OpenProject::Common::DurationComponent.new(meeting.duration, :hours, abbreviated: true).text +
        ")"
    end

    def badge_text
      case meeting.state
      when "open"
        I18n.t("label_meeting_state_open")
      when "in_progress"
        I18n.t("label_meeting_state_in_progress")
      when "closed"
        I18n.t("label_meeting_state_closed")
      else
        meeting.state
      end
    end

    def badge_color
      meetings_state_color.hexcode&.sub("#", "") || "F0F0F0"
    end

    def meetings_state_color
      case meeting.state
      when "in_progress"
        Meetings::Statuses::IN_PROGRESS.color
      when "closed"
        Meetings::Statuses::CLOSED.color
      else
        Meetings::Statuses::OPEN.color
      end
    end

    def meeting_title
      if meeting.recurring?
        "#{format_date(meeting.start_date)} - #{meeting.title}"
      else
        meeting.title
      end
    end
  end
end
