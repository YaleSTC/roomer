# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LotteryAssignment, type: :model do
  describe 'basic validations' do
    subject { build(:lottery_assignment) }

    it { is_expected.to validate_presence_of(:number) }
    it { is_expected.to validate_numericality_of(:number) }
    it { is_expected.not_to allow_value(1.1).for(:number) }

    it { is_expected.to allow_value(false).for(:selected) }
    it { is_expected.to allow_value(true).for(:selected) }

    it { is_expected.to validate_presence_of(:draw) }
    it { is_expected.to belong_to(:draw) }

    it { is_expected.to have_many(:groups).dependent(:nullify) }
  end

  describe 'factories' do
    it 'has a basic factory' do
      expect(build(:lottery_assignment)).to be_valid
    end
    it 'can be defined by a group' do
      group = create(:draw_in_lottery).groups.first
      lottery = build(:lottery_assignment, :defined_by_group, group: group)
      expect(lottery).to be_valid
    end
  end

  describe 'validations' do
    describe 'draw must be in lottery on create' do
      it do
        draw = create(:draw_in_lottery)
        lottery = build(:lottery_assignment, draw: draw)
        expect(lottery).to be_valid
      end
      it 'fails in other states' do
        draw = create(:draw_with_members, status: 'group_formation')
        group = create(:group, :defined_by_draw, draw: draw)
        lottery = build(:lottery_assignment, draw: draw, groups: [group])
        expect(lottery).not_to be_valid
      end
    end

    describe 'group validations' do
      it 'must have at least one group' do
        lottery = build(:lottery_assignment, clip: nil)
        lottery.groups = []
        expect(lottery).not_to be_valid
      end
    end

    it 'number must be unique within a draw' do
      existing = create(:lottery_assignment)
      lottery = build(:lottery_assignment, draw: existing.draw,
                                           number: existing.number)
      expect(lottery).not_to be_valid
    end

    it 'draw must match group draw' do
      groups = create(:draw_in_lottery).groups
      lottery = build(:lottery_assignment, draw: create(:draw_in_lottery),
                                           groups: groups)
      expect(lottery).not_to be_valid
    end

    it 'groups cannot already have lottery assignments' do
      groups = create(:draw_in_lottery).groups
      create(:lottery_assignment, draw: groups.last.draw, groups: [groups.last])
      lottery = build(:lottery_assignment, clip: nil, draw: groups.last.draw,
                                           groups: groups)
      expect(lottery).not_to be_valid
    end
  end

  describe 'frozen attributes' do
    let(:lottery) { create(:lottery_assignment) }

    it "can't change draw" do
      draw = create(:draw_in_lottery)
      # skips the group must be in draw test
      lottery.group.draw = draw
      expect(lottery.update(draw: draw)).to be_falsey
    end
    it 'raises error if draw is changed' do
      draw = create(:draw_in_lottery)
      lottery.group.draw = draw
      lottery.update(draw: draw)
      expect(lottery.errors[:base])
        .to include('Draw cannot be changed inside lottery')
    end
  end

  it 'can be destroyed' do
    lottery = create(:lottery_assignment)
    expect { lottery.destroy }.to change { described_class.count }.by(-1)
  end

  it 'properly updates groups when created from a clip' do
    clip = create(:clip)
    clip.draw.lottery!
    lottery = described_class.create!(draw: clip.draw, clip: clip, number: 1,
                                      groups: clip.groups)
    expect(lottery.reload.groups).to match_array(clip.groups)
  end

  describe '#update_selected!' do
    it 'updates selected to true when group has suite' do
      group = create(:group_with_suite)
      lottery = group.lottery_assignment
      lottery.update(selected: false)
      expect { lottery.update_selected! }.to \
        change { lottery.selected }.from(false).to(true)
    end
    it 'updates selected to false when group has no suite' do
      lottery = create(:lottery_assignment, selected: true)
      expect { lottery.update_selected! }.to \
        change { lottery.selected }.from(true).to(false)
    end
    it 'does nothing when selected matches the status' do
      lottery = create(:lottery_assignment)
      expect { lottery.update_selected! }.not_to change { lottery.selected }
    end
  end

  describe '#group' do
    context 'when single group' do
      it 'returns the group' do
        lottery = create(:lottery_assignment)
        expect(lottery.group).to eq(lottery.groups.first)
      end
    end

    context 'when multiple groups' do
      it do
        clip = create(:locked_clip)
        clip.draw.lottery!
        lottery = create(:lottery_assignment, :defined_by_clip, clip: clip)
        expect(lottery.group).to eq(nil)
      end
    end
  end

  describe '#leader' do
    it 'returns the clip leader when a clip is present' do
      clip = create(:locked_clip)
      clip.draw.lottery!
      lottery = create(:lottery_assignment, :defined_by_clip, clip: clip)
      expect(lottery.leader).to eq(clip.leader)
    end
    it "returns the first group's leader otherwise" do
      lottery = create(:lottery_assignment)
      expect(lottery.leader).to eq(lottery.groups.first.leader)
    end
  end

  describe '#name' do
    it 'returns the name of the leader with "clip" if for a clip' do
      clip = create(:locked_clip)
      clip.draw.lottery!
      lottery = create(:lottery_assignment, :defined_by_clip, clip: clip)
      expect(lottery.name).to eq(clip.leader.full_name + "'s clip")
    end
    it 'returns the name of the leader with "group" if not for a clip' do
      lottery = create(:lottery_assignment)
      expect(lottery.name).to eq(lottery.group.leader.full_name + "'s group")
    end
  end
end
