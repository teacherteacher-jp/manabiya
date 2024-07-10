class Oyasumi
  class << self
    def oyasumi?(date)
      return true if date.saturday? || date.sunday?
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
      File.readlines(path).map { Date.parse(_1.strip) }
    end
  end
end
