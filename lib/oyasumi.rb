class Oyasumi
  class << self
    def oyasumi?(date)
      return true if date.wednesday? || date.saturday? || date.sunday?
      return true if HolidayJp.holiday?(date)
      return true if vacation?(date)

      false
    end

    def vacation?(date)
      vacations.include?(date)
    end

    def vacations
      @vacations ||= load_vacations
    end

    def load_vacations
      path = Rails.root.join("config/vacations.txt")
      File.readlines(path).filter_map do |line|
        date_str = line.strip.split('→').last
        next if date_str.blank?

        begin
          Date.parse(date_str)
        rescue ArgumentError
          nil
        end
      end.compact
    end

    def current_vacation_period(date = Date.today)
      return nil unless vacation?(date)

      vacation_dates = vacations.sort
      vacation_ranges = group_consecutive_dates(vacation_dates)

      vacation_ranges.each do |range|
        if range.cover?(date)
          return {
            start_date: range.first,
            end_date: range.last,
            message: build_vacation_message(range.first, range.last)
          }
        end
      end

      nil
    end

    private

    def group_consecutive_dates(dates)
      return [] if dates.empty?

      ranges = []
      current_range_start = dates.first
      current_range_end = dates.first

      dates.each_cons(2) do |date1, date2|
        if date2 == date1 + 1.day
          current_range_end = date2
        else
          ranges << (current_range_start..current_range_end)
          current_range_start = date2
          current_range_end = date2
        end
      end

      ranges << (current_range_start..current_range_end)
      ranges
    end

    def build_vacation_message(start_date, end_date)
      start_str = start_date.strftime("%-m/%-d(%a)")
      end_str = end_date.strftime("%-m/%-d(%a)")

      japanese_weekdays = {
        'Sun' => '日',
        'Mon' => '月',
        'Tue' => '火',
        'Wed' => '水',
        'Thu' => '木',
        'Fri' => '金',
        'Sat' => '土'
      }

      start_str.gsub!(/\((Sun|Mon|Tue|Wed|Thu|Fri|Sat)\)/) { "(#{japanese_weekdays[$1]})" }
      end_str.gsub!(/\((Sun|Mon|Tue|Wed|Thu|Fri|Sat)\)/) { "(#{japanese_weekdays[$1]})" }

      "コンコンは#{start_str}から#{end_str}までお休みです"
    end
  end
end
