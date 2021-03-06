# frozen_string_literal: true

#
# Service object for building a user record for creation. Currently takes in a
# username, ultimately will request data from IDR.
class UserBuilder
  include Callable

  # Initialize a UserBuilder
  #
  # @param id_attr [String] the value for the ID attribute, either username
  # (CAS) or e-mail (non-CAS)
  # @param role [String] the role of the user to be built
  # @param querier [#query] a service object to retrieve user profile data from.
  #   This must take the id_attr as an initializer parameter (assigned to :id),
  #   and implement a method :query that returns a hash of user attributes and
  #   values.
  def initialize(id_attr:, role: 'student', querier: nil, overwrite: false)
    @id_attr = id_attr
    @role = role
    @querier = querier&.new(id: id_attr)
    @overwrite = overwrite
    @id_symbol = User.login_attr
    @user = initialize_user
  end

  # Build a user record based on the given input
  #
  # @return [Hash{symbol=>User,Hash,Nil}] a results hash with a message to set
  #   in the flash, nil as the :redirect_object value, the user record as the
  #   :user value, and the :action to render. The :redirect_object is always set
  #   to nil so that handle_action properly renders the template set in :action.
  def build
    return invalid_error if id_attr.empty?
    return duplicate_error unless overwrite || !exists?
    return invalid_role_error unless role.in?(User.roles.keys)
    set_attributes
    success
  end

  make_callable :build

  # Returns whether the identifying attribute is already assigned to a different
  # user
  #
  # @return [Boolean] whether or not a user with that identifying attribute
  #   already exists
  def exists?
    @count ||= User.where(id_symbol => id_attr).count
    @count.positive?
  end

  private

  attr_accessor :user
  attr_reader :id_attr, :id_symbol, :querier, :role, :overwrite

  def initialize_user
    user = User.find_by(id_symbol => id_attr) if @overwrite
    return user if user.present?
    empty_user
  end

  def result_hash
    { redirect_object: nil, user: user }
  end

  def success
    result_hash.merge(action: 'new',
                      msg: { success: 'Initialized user successfully' })
  end

  def invalid_error
    result_hash.merge(action: 'build',
                      msg: { error: 'You must enter a username / e-mail' })
  end

  def duplicate_error
    result_hash.merge(action: 'build',
                      msg: { error: 'User already exists' })
  end

  def invalid_role_error
    result_hash.merge(action: 'build',
                      msg: { error: 'Invalid role provided' })
  end

  def empty_user
    return User.new if User.cas_auth?
    assign_initial_password
  end

  def set_attributes
    assign_login_college_and_role
    assign_profile_attrs
  end

  def assign_initial_password
    user = User.new
    password = User.random_password
    user.password = password
    user.password_confirmation = password
    user
  end

  def assign_login_college_and_role
    assign_method = "#{id_symbol}=".to_sym
    user.send(assign_method, id_attr)
    user.role = role
    user.college = College.current
  end

  def assign_profile_attrs
    user.assign_attributes(querier&.query || {})
  end
end
