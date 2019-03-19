# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RoomPolicy do
  subject { described_class }

  let(:room) { build_stubbed(:room) }

  context 'student' do
    let(:user) { build_stubbed(:user, role: 'student') }

    permissions :show?, :destroy?, :edit?, :update? do
      it { is_expected.not_to permit(user, room) }
    end
    permissions :new?, :create?, :index? do
      it { is_expected.not_to permit(user, Room) }
    end
  end

  context 'housing rep' do
    let(:user) { build_stubbed(:user, role: 'rep') }

    permissions :show?, :new?, :create?, :index? do
      it { is_expected.not_to permit(user, Room) }
    end
    permissions :destroy?, :edit?, :update? do
      it { is_expected.not_to permit(user, room) }
    end
  end

  context 'admin' do
    let(:user) { build_stubbed(:user, role: 'admin') }

    permissions :show?, :edit?, :update?, :destroy? do
      it { is_expected.to permit(user, room) }
    end
    permissions :new?, :create?, :index? do
      it { is_expected.to permit(user, Room) }
    end
  end
end
