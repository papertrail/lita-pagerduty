module PagerdutyHelper
  # Shim that will handle querying multiple accounts
  class MultiAccountShim

    attr_accessor :accounts

    # Receives a hash with all the accounts
    def initialize(accountList)
      @accounts = accountList
    end

    def get_schedules
      results = nil
      @accounts.each do |account|
        name = account[:name]
        client = ::Pagerduty.new(token: account[:api_key], subdomain: account[:subdomain])
        partial = client.get_schedules
        partial.schedules.each {|s| s.pd_account = name; puts s.name}
        if results.nil?
          results = partial
        else
          results.schedules = results.schedules + partial.schedules
        end
      end
      results
    end

    def get_users(*args)
      results = nil
      @accounts.each do |name, client|
        partial = client.get_users(*args)
        if results.nil?
          results = partial
        else
          results + partial
        end
      end
      results.uniq
    end

    def get_schedule_users(*args)
      results = []
      @accounts.each do |name, client|
        partial = client.get_schedule_users(*args).first
        partial.account_name = name
        results << partial
      end
      results
    end

    def create_schedule_override
      nil
    end

    # Should find it eventually
    def get_incident(*args)
      results = nil
      @accounts.each do |name, client|
        partial = client.get_incident(*args)
        next if partial == 'No results'
        results = partial
      end
      results
    end

    def incidents
      results = nil
      @accounts.each do |name, client|
        partial = client.incidents
        partial.incidents.each {|s| s.pd_account = name}
        if results.nil?
          results = partial
        else
          results.incidents + partial.incidents
        end
      end
      results
    end
  end
end