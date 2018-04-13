require 'spec_helper'

describe Lita::Handlers::PagerdutyIncident, lita_handler: true do
  include_context 'basic fixtures'

  it do
    is_expected.to route_command('pager incidents all').to(:incidents_all)
    is_expected.to route_command('pager incidents mine').to(:incidents_mine)
    is_expected.to route_command('pager incident ABC123').to(:incident)
  end

  before do
    Lita.config.handlers.pagerduty.escalation_policies = ['Escalation Policy 1', 'Escalation Policy 2']
  end

  describe '#incidents_all' do
    describe 'when there are open incidents' do
      it 'shows a list of incidents' do
        expect(Pagerduty).to receive(:new) { incidents }
        send_command('pager incidents all')
        expect(replies.last).to eq('ABC789: "Still broke", assigned to: '\
                                   'bar@example.com, url: https://acme.pagerduty.com/incidents/ABC789')
      end
    end

    describe 'when there are no open incidents' do
      it 'shows a warning' do
        expect(Pagerduty).to receive(:new) { no_incidents }
        send_command('pager incidents all')
        expect(replies.last).to eq('No triggered, open, or acknowledged ' \
                                   'incidents')
      end
    end

    describe 'when no incidents match the Escalation Policies' do
      it 'shows a warning' do
        expect(Pagerduty).to receive(:new) { incidents_diff_policies }
        send_command('pager incidents all')
        expect(replies.last).to eq('No triggered, open, or acknowledged ' \
                                   'incidents')
      end
    end

    describe 'when one Escalation Policy matches' do
      it 'only acks matching escalation policy' do
        expect(Pagerduty).to(receive(:new) { incidents_one_matching })
        send_command('pager incidents all')
        expect(replies.last).to eq('ABC123: "something broke", assigned to: '\
                                   'foo@example.com, url: https://acme.pagerduty.com/incidents/ABC123')
      end
    end
  end

  describe '#incidents_mine' do
    describe 'when there are open incidents for the user' do
      it 'shows a list of incidents' do
        bar = Lita::User.create(123, name: 'bar')
        expect(Pagerduty).to receive(:new) { incidents }
        send_command('pager identify bar@example.com', as: bar)
        send_command('pager incidents mine', as: bar)
        expect(replies.last).to eq('ABC789: "Still broke", assigned to: ' \
                                   'bar@example.com, url: https://acme.pagerduty.com/incidents/ABC789')
      end
    end

    describe 'when there are no open incidents for the user' do
      it 'shows no incidents' do
        foo = Lita::User.create(123, name: 'foo')
        expect(Pagerduty).to receive(:new) { incidents }
        send_command('pager identify foo@example.com', as: foo)
        send_command('pager incidents mine', as: foo)
        expect(replies.last).to eq('You have no triggered, open, or ' \
                                   'acknowledged incidents')
      end
    end

    describe 'when the user has not identified themselves' do
      it 'shows a warning' do
        send_command('pager incidents mine')
        expect(replies.last).to eq('You have not identified yourself (use ' \
                                   'the help command for more info)')
      end
    end
  end

  describe '#incident' do
    describe 'when the incident exists' do
      it 'shows incident details' do
        expect(Pagerduty).to receive(:new) { new_incident }
        send_command('pager incident ABC123')
        expect(replies.last).to eq('ABC123: "something broke", ' \
                                   'assigned to: foo@example.com, ' \
                                   'url: https://acme.pagerduty.com/incidents/ABC123')
      end
    end

    describe 'when the incident does not exist' do
      it 'shows an error' do
        expect(Pagerduty).to receive(:new) { no_incident }
        send_command('pager incident ABC123')
        expect(replies.last).to eq('ABC123: Incident not found')
      end
    end

    describe 'when the incident id is longer than 6 characters' do
      it 'shows the incident details' do
        expect(Pagerduty).to receive(:new) { incident_with_long_id }
        send_command('pager incident ABC123456789')
        expect(replies.last).to eq('ABC123456789: "something broke", ' \
                                   'assigned to: foo@example.com, ' \
                                   'url: https://acme.pagerduty.com/incidents/ABC123456789')
      end
    end

    describe 'when the incident is not assigned to anyone' do
      it 'shows incident details with none user' do
        expect(Pagerduty).to receive(:new) { incident_without_assigned_user }
        send_command('pager incident ABC456')
        expect(replies.last).to eq('ABC456: "something broke", ' \
                                   'assigned to: none, ' \
                                   'url: https://acme.pagerduty.com/incidents/ABC456')
      end
    end
  end
end
