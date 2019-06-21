# frozen_string_literal: true

# Service / form object for email exports
#
# @attr draw_id [Integer] the draw_id to scope to, if any; set to zero for
#   drawless groups only
# @attr size [Integer,Nil] the size to scope to, if any
# @attr leaders_only [Boolean] whether to scope to all members
#   or only leaders; default is true
# @attr locked [Boolean] whether or not to scope to locked groups only
class EmailExport
  include ActiveModel::Model

  attr_accessor :draw_id, :size, :locked, :leaders_only
  attr_reader :users

  validates :draw_id, numericality: { only_integer: true, allow_nil: true,
                                      greater_than_or_equal_to: 0 }
  validates :size, numericality: { only_integer: true, allow_nil: true,
                                   greater_than: 0 }
  validates :locked, inclusion: { in: [true, false] }
  validates :leaders_only, inclusion: { in: [true, false] }

  # Initialize a new EmailExport, nillifies empty strings for draw_id and
  # converts locked and leaders_only to actual booleans
  # (the default input from a checkbox is a string '1' or '0')
  def initialize(*args)
    super(*args)

    # Locked defaults to false, leaders_only to true
    # (that's why the ternaries here are in the order they're in)
    @locked = locked == '1' ? true : false
    @leaders_only = leaders_only == '0' ? false : true
    process_draw_id
  end

  # Generate the e-mail export, collects the relevant groups and their leaders
  #
  # @return [EmailExport] the email export object, will have a leaders attribute
  #   populated with the query results if it succeeded
  def generate
    execute_query if valid?
    self
  end

  # Determine whether or not the query was scoped to a specific draw or to
  # drawless groups
  #
  # @return [Boolean] whether or not the export was scoped to draw_id
  def draw_scoped?
    draw_scope || false
  end

  private

  attr_reader :draw_scope

  def process_draw_id
    return unless draw_id.present?
    @draw_scope = true
    self.draw_id = nil if draw_id.to_i.zero?
  end

  def execute_query # rubocop:disable AbcSize
    query = User.active
                .includes(draw_membership: leaders_only ? :led_group : :group)
                .where.not(groups: { id: nil }).order(:last_name, :first_name)
    if draw_scope
      query = query.where(groups: { draw_memberships: { draw_id: draw_id } })
    end
    query = query.where(groups: { size: size }) if size.present?
    query = query.where(groups: { status: Group.statuses['locked'] }) if locked
    @users = query.to_a
  end
end
