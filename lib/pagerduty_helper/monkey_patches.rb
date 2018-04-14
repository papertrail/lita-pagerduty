# Monkey Patch User, Incident and Schedule
# to support the notion of Accounts

class Pagerduty
  class Schedules
    class Schedule
      attr_accessor :pd_account
    end
  end
end

class Pagerduty
  class Incidents
    class Incident
      attr_accessor :pd_account
    end
  end
end