# frozen_string_literal: true

#
# Service object to create users.
class UserCreator
  include Callable

  # Initialize a UserCreator
  #
  # @param [ActionController::Parameters] params The params object from
  #   the UsersController.
  def initialize(params:, mailer: UserMailer)
    @params = params.to_h.symbolize_keys
    @draw_membership_params = @params.delete(:draw_membership).to_h.symbolize_keys
    @mailer = mailer
    @user = User.new(**@params)
    set_password unless User.cas_auth?
    set_college unless user.superadmin?
  end

  # Attempt to create a new user. If CAS auth is NOT enabled, autogenerates a
  # password and sends it in the confirmation e-mail.
  #
  # @return [Hash{Symbol=>User,Hash}] a results hash with a message to set in
  #   the flash, the user record (persisted or not), and either nil or the
  #   record as the :redirect_object value
  def create!
    user.save!
    create_draw_membership!
    mailer.new_user_confirmation(user: user, password: password).deliver_later
    success
  rescue ActiveRecord::RecordInvalid => e
    error(e)
  end

  make_callable :create!

  private

  attr_accessor :password, :user
  attr_reader :mailer

  def set_password
    @password ||= User.random_password
    user.password = @password
    user.password_confirmation = @password
  end

  def set_college
    user.college = College.current
  end

  def create_draw_membership!
    return unless @draw_membership_params[:draw_id].present?
    DrawMembership.create!(user_id: @user.id, **@draw_membership_params)
  end

  def success
    {
      redirect_object: user, user: user,
      msg: { success: "User #{user.full_name} created." }
    }
  end

  def error(error_obj)
    msg = ErrorHandler.format(error_object: error_obj)
    {
      redirect_object: nil, user: user,
      msg: { error: "Please review the errors below:\n#{msg}" }
    }
  end
end
