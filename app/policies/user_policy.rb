# frozen_string_literal: true

# Class for User permissions
class UserPolicy < ApplicationPolicy
  def show?
    true
  end

  def edit?
    update?
  end

  def update?
    user.admin?
  end

  def edit_password?
    update_password?
  end

  def update_password?
    (record == user) && !User.cas_auth?
  end

  def edit_intent?
    update_intent?
  end

  def update_intent?
    (valid_student_rep_update || valid_admin_update) && !record.group.present?
  end

  def build?
    new?
  end

  def draw_info?
    !record.admin? && record.draw.present?
  end

  def browsable?
    !record.graduated?
  end

  class Scope < Scope # rubocop:disable Style/Documentation
    def resolve
      scope.where(college: College.current).active
    end
  end

  private

  def valid_student_rep_update
    (user.rep? || record == user) &&
      intent_selection_or_group_formation &&
      !record.draw.intent_locked
  end

  def intent_selection_or_group_formation
    record&.draw&.group_formation? || record&.draw&.intent_selection?
  end

  def valid_admin_update
    user.admin? && record&.draw&.before_lottery?
  end
end
