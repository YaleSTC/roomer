# frozen_string_literal: true
require 'rails_helper'

RSpec.describe MembershipUpdater do
  describe '.update' do
    it 'calls :update on an instance of MembershipUpdater' do
      params = { membership: nil, params: nil }
      membership_updater = mock_membership_updater(params)
      described_class.update(params)
      expect(membership_updater).to have_received(:update)
    end
  end

  # rubocop:disable RSpec/ExampleLength
  it 'returns an array with the draw and the group from the membership' do
    group = instance_spy('Group', draw: instance_spy('Draw'))
    membership = instance_spy('Membership',
                              group: group, update_attributes: true,
                              user: instance_spy('User', full_name: 'Name'))
    params = instance_spy('ActionController::Parameters', to_h: {})
    updater = described_class.new(membership: membership, params: params)
    expect(updater.update[:object]).to eq([group.draw, group])
  end
  # rubocop:enable RSpec/ExampleLength

  def mock_membership_updater(param_hash)
    instance_spy('MembershipUpdater').tap do |mu|
      allow(described_class).to receive(:new).with(param_hash).and_return(mu)
    end
  end
end
