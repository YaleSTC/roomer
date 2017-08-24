# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Suite, type: :model do
  describe 'basic validations' do
    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to belong_to(:building) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:rooms) }
    it { is_expected.to have_many(:draws_suites) }
    it { is_expected.to have_many(:draws).through(:draws_suites) }

    describe 'number uniqueness' do
      it 'allows duplicates that belong to separate buildings' do
        number = 'L01'
        FactoryGirl.create(:suite, number: number)
        suite = FactoryGirl.build(:suite, number: number)
        expect(suite.valid?).to be_truthy
      end
      it 'does not allow duplicates in the same building' do
        attrs = { number: 'L01', building: FactoryGirl.create(:building) }
        FactoryGirl.create(:suite, **attrs)
        suite = FactoryGirl.build(:suite, **attrs)
        expect(suite.valid?).to be_falsey
      end
    end
  end

  context 'scopes' do
    describe '.available' do
      it 'returns all suites not assigned to groups' do
        suite1 = FactoryGirl.create(:suite, number: 'def')
        suite2 = FactoryGirl.create(:suite, number: 'abc')
        FactoryGirl.create(:suite, group_id: 1234)
        expect(described_class.available.map(&:id)).to \
          eq([suite1.id, suite2.id])
      end
    end
  end

  it 'clears room ids when group assignment changes' do
    group = FactoryGirl.create(:locked_group, size: 1)
    suite = FactoryGirl.create(:suite_with_rooms, group_id: group.id)
    group.leader.update!(room_id: suite.rooms.first.id)
    expect { group.suite.update!(group_id: nil) }.to \
      change { group.leader.reload.room_id }.from(suite.rooms.first.id).to(nil)
  end

  it 'removes other draws if already assigned' do
    draw1 = FactoryGirl.create(:draw)
    draw2 = FactoryGirl.create(:draw)
    group = FactoryGirl.create(:locked_group, size: 1)
    suite = FactoryGirl.create(:suite_with_rooms, draws: [draw1, draw2])
    group.leader.update!(room_id: suite.rooms.first.id, draw: draw1)
    expect { suite.update!(group_id: group.id) }.to \
      change { suite.draws.to_a }.to([])
  end

  it 'removes draws if changed to a medical suite' do
    draw = FactoryGirl.create(:draw)
    suite = FactoryGirl.create(:suite, draws: [draw])
    expect { suite.update!(medical: true) }.to \
      change { suite.draws.to_a }.to([])
  end

  describe '.size_str' do
    it 'raises an argument error if a non-integer is passed' do
      size = instance_spy('string')
      allow(size).to receive(:is_a?).with(Integer).and_return(false)
      expect { described_class.size_str(size) }.to raise_error(ArgumentError)
    end
    it 'raises an argument error if a non-positive number is passed' do
      size = instance_spy('integer')
      allow(size).to receive(:positive?).and_return(false)
      expect { described_class.size_str(size) }.to raise_error(ArgumentError)
    end
    context 'valid inputs' do
      expected = { 1 => 'single', 2 => 'double', 3 => 'triple',
                   4 => 'quad', 5 => 'quint', 6 => 'sextet',
                   7 => 'septet', 8 => 'octet', 9 => '9-pack' }
      expected.each do |size, expected_str|
        it "returns a valid result for #{size}" do
          expect(described_class.size_str(size)).to eq(expected_str)
        end
      end
    end
  end

  describe '#size' do
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.not_to allow_value(-1).for(:size) }
    it { is_expected.to allow_value(0).for(:size) }
    it 'equals the number of beds in all rooms' do
      size = 2
      suite = FactoryGirl.create(:suite)
      size.times { FactoryGirl.create(:room, beds: 1, suite: suite) }
      expect(suite.size).to eq(size)
    end
  end

  describe '#name_with_draws' do
    it 'returns the name if the suite belongs to no draws' do
      suite = FactoryGirl.build_stubbed(:suite)
      allow(suite).to receive(:draws).and_return([])
      expect(suite.name_with_draws).to eq(suite.name)
    end
    it 'returns the name if the suite only belongs to the passed draw' do
      suite = FactoryGirl.create(:suite)
      draw = FactoryGirl.create(:draw)
      suite.draws << draw
      expect(suite.name_with_draws(draw)).to eq(suite.name)
    end
    it 'returns the name with other draw names' do
      suite = FactoryGirl.create(:suite)
      draw = FactoryGirl.create(:draw)
      suite.draws << draw
      expected = "#{suite.name} (#{draw.name})"
      expect(suite.name_with_draws).to eq(expected)
    end
    it 'excludes the passed draw' do
      draw = FactoryGirl.create(:draw_with_members, suites_count: 1,
                                                    students_count: 0)
      draw2 = FactoryGirl.create(:draw)
      expected = "#{draw.suites.first.name} (#{draw.name})"
      expect(draw.suites.first.name_with_draws(draw2)).to eq(expected)
    end
  end

  describe '#available?' do
    it 'returns true if the suite has no group assigned' do
      suite = FactoryGirl.build(:suite, group_id: nil)
      expect(suite).to be_available
    end
    it 'returns false if the suite has a group assigned' do
      suite = FactoryGirl.build(:suite, group_id: 123)
      expect(suite).not_to be_available
    end
  end

  describe 'room helpers' do
    let(:suite) { FactoryGirl.create(:suite) }
    let(:single) { FactoryGirl.create(:single) }
    let(:double) { FactoryGirl.create(:double) }
    let(:common) { FactoryGirl.create(:room, beds: 0) }

    before do
      suite.rooms << single
      suite.rooms << double
      suite.rooms << common
    end

    describe '#singles' do
      it 'returns all of the single rooms belonging to the suite' do
        expect(suite.singles).to eq([single])
      end
    end
    describe '#doubles' do
      it 'returns all of the double rooms belonging to the suite' do
        expect(suite.doubles).to eq([double])
      end
    end
    describe '#common_rooms' do
      it 'returns all of the common rooms belonging to the suite' do
        expect(suite.common_rooms).to eq([common])
      end
    end
  end

  describe '#selectable?' do
    it "returns true if the suite isn't selectable in another draw" do
      suite = FactoryGirl.build_stubbed(:suite)
      allow(suite).to receive(:draws)
        .and_return(mock_draws(%i(pre_lottery? draft?)))
      expect(suite).to be_selectable
    end

    it "returns false if one of the suite's draws is in the lottery phase" do
      suite = FactoryGirl.build_stubbed(:suite)
      allow(suite).to receive(:draws)
        .and_return(mock_draws(%i(pre_lottery? draft? lottery?)))
      expect(suite).not_to be_selectable
    end

    it 'returns false if a draw is in the suite_selection phase' do
      suite = FactoryGirl.build_stubbed(:suite)
      allow(suite).to receive(:draws)
        .and_return(mock_draws(%i(pre_lottery? draft? suite_selection?)))
      expect(suite).not_to be_selectable
    end

    def mock_draws(statuses)
      default_statuses = { draft?: false, pre_lottery?: false, lottery?: false,
                           suite_selection?: false }
      statuses.map do |s|
        status_hash = default_statuses.merge(s => true)
        instance_spy('draw', **status_hash)
      end
    end
  end

  describe '#number_with_medical' do
    let(:suite) { FactoryGirl.build_stubbed(:suite) }

    it 'returns the number if not a medical suite' do
      allow(suite).to receive(:medical).and_return(false)
      expect(suite.number_with_medical).to eq(suite.number)
    end
    it 'indicates if the suite is a medical suite' do
      allow(suite).to receive(:medical).and_return(true)
      expected = "#{suite.number} (medical)"
      expect(suite.number_with_medical).to eq(expected)
    end
  end

  describe '#name' do
    let(:suite) { FactoryGirl.build_stubbed(:suite) }
    let(:building) { suite.building }

    it 'returns the building name and suite number' do
      expected = "#{building.name} #{suite.number}"
      expect(suite.name).to eq(expected)
    end
  end
end
