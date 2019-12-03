# frozen_string_literal: true

# rubocop:disable RSpec/NestedGroups, RSpec/ScatteredSetup
require 'rails_helper'

RSpec.describe UserPolicy do
  subject { described_class }

  let(:other_user) { build_stubbed(:user) }

  context 'student' do
    let(:user) { build_stubbed(:user, role: 'student') }

    permissions :show? do
      it { is_expected.to permit(user, user) }
      it { is_expected.to permit(user, other_user) }
    end
    context 'profile attribute changing' do
      permissions :edit?, :update? do
        it { is_expected.not_to permit(user, user) }
        it { is_expected.not_to permit(user, other_user) }
      end
    end
    context 'password changing' do
      permissions :edit_password?, :update_password? do
        it { is_expected.not_to permit(user, other_user) }
        it { is_expected.to permit(user, user) }
      end
    end

    permissions :browsable? do
      context 'when user has not graduated' do
        before { allow(user).to receive(:graduated?).and_return(false) }
        it { is_expected.to permit(user, user) }
      end
      context 'when user has graduated' do
        before { allow(user).to receive(:graduated?).and_return(true) }
        it { is_expected.not_to permit(user, user) }
      end
    end

    permissions :edit_intent?, :update_intent? do
      context 'user is not in a draw' do
        before { allow(user).to receive(:draw).and_return(nil) }
        it { is_expected.not_to permit(user, user) }
      end

      context 'user is in a draw' do
        let(:draw) { instance_spy('draw') }

        before { allow(user).to receive(:draw).and_return(draw) }

        context 'draw is not group-formation' do
          before { allow(draw).to receive(:group_formation?).and_return(false) }
          it { is_expected.not_to permit(user, user) }
        end

        context 'draw is not intent-selection' do
          before do
            allow(draw).to receive(:intent_selection?).and_return(false)
          end

          it { is_expected.not_to permit(user, user) }
        end

        context 'draw is in intent-selection' do
          before { allow(draw).to receive(:intent_selection?).and_return(true) }
          before { allow(draw).to receive(:intent_locked).and_return(false) }
          it { is_expected.to permit(user, user) }
        end

        context 'draw is group-formation' do
          let(:group) { instance_spy('group', present?: true) }

          before { allow(draw).to receive(:group_formation?).and_return(true) }

          context 'user has a group' do
            before { allow(user).to receive(:group).and_return(group) }
            it { is_expected.not_to permit(user, user) }
          end

          context 'user does not have a group' do
            before { allow(user).to receive(:group).and_return(nil) }

            context 'draw intent is locked' do
              before { allow(draw).to receive(:intent_locked).and_return(true) }
              it { is_expected.not_to permit(user, user) }
            end

            context 'draw intent is not locked' do
              before do
                allow(draw).to receive(:intent_locked).and_return(false)
              end

              context 'user is not current_user' do
                it { is_expected.not_to permit(user, other_user) }
              end
              context 'user is current_user' do
                it { is_expected.to permit(user, user) }
              end
            end
          end
        end
      end
    end
    permissions :destroy?, :update?, :edit?, :edit_intent?, :update_intent? do
      it { is_expected.not_to permit(user, other_user) }
    end
    permissions :index?, :build?, :create?, :new? do
      it { is_expected.not_to permit(user, User) }
    end
    permissions :draw_info? do
      context 'other user is admin' do
        before { allow(other_user).to receive(:admin?).and_return(true) }
        it { is_expected.not_to permit(user, other_user) }
      end
      context 'other user is not in draw' do
        before { allow(other_user).to receive(:draw).and_return(nil) }
        it { is_expected.not_to permit(user, other_user) }
      end
      context 'non-admin in draw' do
        before do
          allow(other_user).to receive(:admin?).and_return(false)
          allow(other_user).to \
            receive(:draw).and_return(instance_spy('draw', present?: true))
        end
        it { is_expected.to permit(user, other_user) }
      end
    end
  end

  context 'housing rep' do
    let(:user) { build_stubbed(:user, role: 'rep') }

    permissions :show? do
      it { is_expected.to permit(user, other_user) }
    end
    permissions :browsable? do
      context 'when user has not graduated' do
        before { allow(user).to receive(:graduated?).and_return(false) }
        it { is_expected.to permit(user, user) }
      end
      context 'when user has graduated' do
        before { allow(user).to receive(:graduated?).and_return(true) }
        it { is_expected.not_to permit(user, user) }
      end
    end
    permissions :edit?, :update? do
      it { is_expected.not_to permit(user, user) }
    end
    permissions :show?, :edit_password?, :update_password? do
      it { is_expected.to permit(user, user) }
    end
    permissions :destroy?, :update?, :edit?, :edit_password?,
                :update_password? do
      it { is_expected.not_to permit(user, other_user) }
    end
    permissions :index?, :build?, :create?, :new? do
      it { is_expected.not_to permit(user, User) }
    end
    permissions :edit_intent?, :update_intent? do
      context 'other user is not in a draw' do
        before { allow(other_user).to receive(:draw).and_return(nil) }
        it { is_expected.not_to permit(user, other_user) }
      end

      context 'other user is in a draw' do
        let(:draw) { instance_spy('draw') }

        before { allow(other_user).to receive(:draw).and_return(draw) }

        context 'draw is not group-formation' do
          before { allow(draw).to receive(:group_formation?).and_return(false) }
          it { is_expected.not_to permit(user, other_user) }
        end

        context 'draw is group-formation' do
          let(:group) { instance_spy('group', present?: true) }

          before { allow(draw).to receive(:group_formation?).and_return(true) }

          context 'other user has a group' do
            before { allow(other_user).to receive(:group).and_return(group) }
            it { is_expected.not_to permit(user, other_user) }
          end

          context 'other user does not have a group' do
            before { allow(other_user).to receive(:group).and_return(nil) }

            context 'draw intent is locked' do
              before { allow(draw).to receive(:intent_locked).and_return(true) }
              it { is_expected.not_to permit(user, other_user) }
            end

            context 'draw intent is not locked' do
              before do
                allow(draw).to receive(:intent_locked).and_return(false)
              end
              it { is_expected.to permit(user, other_user) }
            end
          end
        end
      end

      context 'user is not in a draw' do
        before { allow(user).to receive(:draw).and_return(nil) }
        it { is_expected.not_to permit(user, user) }
      end

      context 'user is in a draw' do
        let(:draw) { instance_spy('draw') }

        before { allow(user).to receive(:draw).and_return(draw) }

        context 'draw is not group-formation' do
          before { allow(draw).to receive(:group_formation?).and_return(false) }
          it { is_expected.not_to permit(user, user) }
        end

        context 'draw is group-formation' do
          let(:group) { instance_spy('group', present?: true) }

          before { allow(draw).to receive(:group_formation?).and_return(true) }

          context 'user has a group' do
            before { allow(user).to receive(:group).and_return(group) }
            it { is_expected.not_to permit(user, user) }
          end

          context 'user does not have a group' do
            before { allow(user).to receive(:group).and_return(nil) }

            context 'draw intent is locked' do
              before { allow(draw).to receive(:intent_locked).and_return(true) }
              it { is_expected.not_to permit(user, user) }
            end

            context 'draw intent is not locked' do
              before do
                allow(draw).to receive(:intent_locked).and_return(false)
              end
              context 'user is not current_user' do
                it { is_expected.not_to permit(user, other_user) }
              end
              context 'user is current_user' do
                it { is_expected.to permit(user, user) }
              end
            end
          end
        end
      end
    end

    permissions :draw_info? do
      context 'other user is admin' do
        before { allow(other_user).to receive(:admin?).and_return(true) }
        it { is_expected.not_to permit(user, other_user) }
      end
      context 'other user is not in draw' do
        before { allow(other_user).to receive(:draw).and_return(nil) }
        it { is_expected.not_to permit(user, other_user) }
      end
      context 'non-admin in draw' do
        before do
          allow(other_user).to receive(:admin?).and_return(false)
          allow(other_user).to \
            receive(:draw).and_return(instance_spy('draw', present?: true))
        end
        it { is_expected.to permit(user, other_user) }
      end
    end
  end

  context 'admin' do
    let(:user) { build_stubbed(:user, role: 'admin') }

    permissions :show?, :destroy?, :update?, :edit? do
      it { is_expected.to permit(user, other_user) }
    end
    permissions :index?, :build?, :create?, :new? do
      it { is_expected.to permit(user, User) }
    end
    permissions :edit_password?, :update_password? do
      it { is_expected.not_to permit(user, other_user) }
      it { is_expected.to permit(user, user) }
    end

    permissions :browsable? do
      context 'when user has not graduated' do
        before { allow(user).to receive(:graduated?).and_return(false) }
        it { is_expected.to permit(user, user) }
      end
      context 'when user has graduated' do
        before { allow(user).to receive(:graduated?).and_return(true) }
        it { is_expected.not_to permit(user, user) }
      end
    end

    permissions :edit_intent?, :update_intent? do
      context 'other user is not in a draw' do
        before { allow(other_user).to receive(:draw).and_return(nil) }
        it { is_expected.not_to permit(user, other_user) }
      end
      context 'other user is in a draw' do
        let(:draw) { instance_spy('draw') }

        before { allow(other_user).to receive(:draw).and_return(draw) }

        context 'draw is not before lottery' do
          before { allow(draw).to receive(:before_lottery?).and_return(false) }
          it { is_expected.not_to permit(user, other_user) }
        end

        context 'draw is before lottery' do
          let(:group) { instance_spy('group', present?: true) }

          before { allow(draw).to receive(:before_lottery?).and_return(true) }

          context 'other user has a group' do
            before { allow(other_user).to receive(:group).and_return(group) }
            it { is_expected.not_to permit(user, other_user) }
          end
          context 'other user does not have a group' do
            before { allow(other_user).to receive(:group).and_return(nil) }
            it { is_expected.to permit(user, other_user) }
          end
        end
      end
    end

    permissions :draw_info? do
      context 'other user is admin' do
        before { allow(other_user).to receive(:admin?).and_return(true) }
        it { is_expected.not_to permit(user, other_user) }
      end
      context 'other user is not in draw' do
        before { allow(other_user).to receive(:draw).and_return(nil) }
        it { is_expected.not_to permit(user, other_user) }
      end
      context 'non-admin in draw' do
        before do
          allow(other_user).to receive(:admin?).and_return(false)
          allow(other_user).to \
            receive(:draw).and_return(instance_spy('draw', present?: true))
        end
        it { is_expected.to permit(user, other_user) }
      end
    end
  end
end
