# frozen_string_literal: true
#
# Query to return the students who do not currently belong to any group, i.e. do
#   belong to a membership. This can be passed an existing relation for a subset
#   of all students.
class UngroupedStudentsQuery
  # See IntentMetricsQuery for explanation.
  class << self
    delegate :call, to: :new
  end

  # Initialize an UngroupedStudentsQuery
  #
  # @param relation [User::ActiveRecord_Relation] the base relation for the
  #   query
  def initialize(relation = User.all)
    @relation = relation
  end

  # Execute the ungrouped students query. Filters students by role and performs
  #   an inverse join with the memberships table. See
  #   http://stackoverflow.com/a/9429191 for more details.
  #
  # @return [Array<User>] the ungrouped students in the relation
  def call
    @relation.where(role: %w(student rep)).left_outer_joins(:membership)
             .where(memberships: { user_id: nil })
  end
end
