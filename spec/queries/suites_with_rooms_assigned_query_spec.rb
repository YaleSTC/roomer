# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SuitesWithRoomsAssignedQuery do
  it 'returns all suites with rooms assigned' do
    assigned = create_suite_with_rooms_assigned
    _unassigned = create(:suite_with_rooms)
    expect(described_class.call).to match_array([assigned])
  end

  it 'can be scoped' do
    expected = create_suite_with_rooms_assigned(size: 1)
    _unexpected = create_suite_with_rooms_assigned(size: 2)
    result = described_class.new(Suite.where(size: 1)).call
    expect(result).to match_array([expected])
  end

  it 'orders results by suite number' do
    second = create_suite_with_rooms_assigned(number: '21')
    first = create_suite_with_rooms_assigned(number: '12')
    expect(described_class.call).to match_array([first, second])
  end

  it 'ignores archived suites' do
    archived = create_suite_with_rooms_assigned(size: 1)
    archived.suite_assignment.group.draw_memberships.each do |dm|
      dm.update!(active: false)
    end
    expect(described_class.call).to eq([])
  end

  # rubocop:disable MethodLength
  def create_suite_with_rooms_assigned(size: 1, number: nil)
    base_suite_hash = { rooms_count: size }
    suite_hash = if number
                   base_suite_hash.merge(number: number)
                 else
                   base_suite_hash
                 end
    suite = create(:suite_with_rooms, **suite_hash)
    group = create(:drawless_group, size: size)
    SuiteAssignment.create!(group: group, suite: suite)
    group.members.each_with_index do |student, i|
      RoomAssignment.create!(draw_membership: student.draw_membership,
                             room_id: suite.rooms[i].id)
    end
    suite
  end
  # rubocop:enable MethodLength
end
