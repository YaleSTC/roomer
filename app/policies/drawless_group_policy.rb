# frozen_string_literal: true
#
# Policy for permissions on special (non-draw) housing groups
class DrawlessGroupPolicy < ApplicationPolicy
  def select_suite?
    user.admin? && record.locked?
  end
end
