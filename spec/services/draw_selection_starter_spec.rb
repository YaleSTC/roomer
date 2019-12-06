# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DrawSelectionStarter do
  describe '#start' do
    before do
      l = instance_spy('LotteryAssignment::ActiveRecord_Relation')
      allow(LotteriesWithoutGroupsQuery).to receive(:call).and_return(l)
    end
    it 'checks to make sure that the draw is in lottery' do
      draw = instance_spy('draw', lottery?: false)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to include('in the lottery phase')
    end

    it 'checks to make sure that all groups have lottery numbers assigned' do
      draw = instance_spy('draw', lottery_complete?: false)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to \
        include('All groups must have lottery numbers assigned')
    end

    it 'updates the status of the draw to suite_selection' do
      draw = instance_spy('draw', validity_stubs(valid: true))
      allow(draw).to receive(:update!).with(status: 'suite_selection')
                                      .and_return(true)
      described_class.start(draw: draw)
      expect(draw).to have_received(:update!).with(status: 'suite_selection')
    end

    it 'checks to see if the update works' do
      draw = instance_spy('draw', validity_stubs(valid: true))
      error = ActiveRecord::RecordInvalid.new(build_stubbed(:draw))
      allow(draw).to receive(:update!).and_raise(error)
      result = described_class.start(draw: draw)
      expect(result[:msg][:error]).to include('There was a problem')
    end

    it 'returns the updated draw on success' do
      draw = instance_spy('draw', validity_stubs(valid: true))
      result = described_class.start(draw: draw)
      expect(result[:redirect_object]).to eq(draw)
    end

    it 'sends invitations to the first group(s) to select' do
      msg = instance_spy(ActionMailer::MessageDelivery, deliver_later: 1)
      draw = valid_mock_draw_with_group
      allow(StudentMailer).to receive(:selection_invite).and_return(msg)
      described_class.start(draw: draw)
      expect(StudentMailer).to have_received(:selection_invite)
    end

    context 'sending notifications to all students in the draw' do
      let(:draw) { create(:draw_in_selection).tap(&:lottery!) }
      let(:mailer) { instance_spy('student_mailer') }

      it 'sends a notification the correct number of times' do
        described_class.start(draw: draw, mailer: mailer)
        expect(mailer).to have_received(:lottery_notification)
          .exactly(draw.draw_memberships.on_campus.count).times
      end

      it 'sends a notification with the correct arguments' do
        user, lottery_number, lottery_numbers, college = lottery_params(draw)
        described_class.start(draw: draw, mailer: mailer)
        expect(mailer).to have_received(:lottery_notification)
          .with(user: user, lottery_number: lottery_number,
                lottery_numbers: lottery_numbers, college: college)
      end
    end

    it 'sets the object key to nil in the hash on failure' do
      draw = instance_spy('draw', validity_stubs(valid: false))
      result = described_class.start(draw: draw)
      expect(result[:redirect_object]).to be_nil
    end
  end

  describe '#start!' do
    before do
      l = instance_spy('LotteryAssignment::ActiveRecord_Relation')
      allow(LotteriesWithoutGroupsQuery).to receive(:call).and_return(l)
    end
    it 'raises ActiveModel::ValidationError on validation failure' do
      draw = instance_spy('draw', lottery_complete?: false)
      expect { described_class.start!(draw: draw) }.to \
        raise_error(ActiveModel::ValidationError)
    end
    it 'raises ActiveRecord::RecordInvalid on update failure' do
      draw = instance_spy('draw', validity_stubs(valid: true))
      error = ActiveRecord::RecordInvalid.new(build_stubbed(:draw))
      allow(draw).to receive(:update!).and_raise(error)
      expect { described_class.start!(draw: draw) }.to raise_error(error)
    end
    it 'returns the updated draw on success' do
      draw = instance_spy('draw', validity_stubs(valid: true))
      result = described_class.start!(draw: draw)
      expect(result[:redirect_object]).to eq(draw)
    end
  end

  describe 'validations' do
    it 'remove all lotteries without groups' do
      l = instance_spy('LotteryAssignment::ActiveRecord_Relation')
      allow(LotteriesWithoutGroupsQuery).to receive(:call).and_return(l)
      draw = instance_spy('draw', validity_stubs(valid: true))
      described_class.start!(draw: draw)
      expect(l).to have_received(:destroy_all)
    end
  end

  def mock_draw_selection_starter(param_hash)
    instance_spy('draw_selection_starter').tap do |draw_selection_starter|
      allow(described_class).to receive(:new).with(param_hash)
                                             .and_return(draw_selection_starter)
    end
  end

  def validity_stubs(valid:, **attrs)
    { lottery?: valid, lottery_complete?: valid }.merge(attrs)
  end

  def valid_mock_draw_with_group
    group = instance_spy('group', leader: instance_spy('user'))
    instance_spy('draw', validity_stubs(valid: true, next_groups: [group]))
  end

  def lottery_params(draw)
    user = draw.draw_memberships.on_campus.map(&:user)[0]
    lottery_number = user.group&.lottery_number
    lottery_numbers = lottery_numbers(draw, user)
    college = College.current
    [user, lottery_number, lottery_numbers, college]
  end

  def lottery_numbers(draw, user)
    draw&.groups&.includes(:lottery_assignment)&.
          where(size: user.group&.size)&.map(&:lottery_number)&.sort
  end
end
