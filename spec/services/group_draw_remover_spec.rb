# frozen_string_literal: true
require 'rails_helper'

RSpec.describe GroupDrawRemover do
  describe '.remove' do
    xit 'calls :remove on an instance of GroupDrawRemover'
  end

  describe '#remove' do
    context 'success' do
      let(:member) { instance_spy('user', draw_id: 123) }
      let(:group) { instance_spy('group', draw_id: 123) }
      let(:membership) { instance_spy('membership') }
      let(:invitation) { instance_spy('membership') }
      before do
        allow(group).to receive(:members).and_return([member])
        allow(group).to receive(:pending_memberships).and_return([invitation])
      end
      it 'removes the draw_id from the group' do
        described_class.remove(group: group)
        expect(group).to have_received(:update!).with(draw_id: nil)
      end
      it 'removes the draw_id from members and saves old_draw_id' do
        described_class.remove(group: group)
        expect(member).to have_received(:remove_draw)
      end
      it 'destroys invitations' do
        described_class.remove(group: group)
        expect(invitation).to have_received(:destroy!)
      end
      it 'sets the :object to the group' do
        result = described_class.remove(group: group)
        expect(result[:object]).to eq(group)
      end
      it 'sets a success message' do
        result = described_class.remove(group: group)
        expect(result[:msg].keys).to match([:success])
      end
    end

    context 'failure' do
      let(:draw) { instance_spy('draw') }
      let(:group) { instance_spy('group', draw: draw) }
      before do
        allow(group).to receive(:update!)
          .and_raise(ActiveRecord::RecordInvalid)
      end
      it 'sets the :object to the draw and group' do
        result = described_class.remove(group: group)
        expect(result[:object]).to match([draw, group])
      end
      it 'sets a success message' do
        result = described_class.remove(group: group)
        expect(result[:msg].keys).to match([:error])
      end
    end
  end
end
