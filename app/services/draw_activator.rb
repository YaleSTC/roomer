# frozen_string_literal: true
#
# Service object to handle the activation of a draw. Checks to make sure the
# draw has the correct status, updates the status, and sends e-mail invitations
# to students in the draw.
class DrawActivator
  # Class method to permit calling :activate on the class without instantiating
  # the service object directly
  #
  # @param draw [Draw] the draw in question
  def self.activate(draw:)
    new(draw: draw).activate
  end

  # Initialize a new DrawActivator
  #
  # @param draw [Draw] the draw in question
  # @param mailer [ActionMailer::Base] mailer class for sending invitation
  #   e-mails
  def initialize(draw:, mailer: StudentMailer)
    @draw = draw
    @errors = []
    @mailer = mailer
    @college = College.first
  end

  # Activate a Draw
  #
  # @return [Hash{Symbol=>ApplicationRecord,Hash}] A results hash with the
  #   message to set in the flash and either `nil` or the created object.
  def activate
    validate
    activate_draw if currently_valid?
    send_emails if currently_valid?
    currently_valid? ? success : error
  end

  private

  attr_accessor :draw, :errors
  attr_reader :college, :mailer

  def validate
    errors << 'Draw must be a draft.' unless draw.draft?
    errors << 'Draw must have at least one student.' unless draw.students?
    return if draw.enough_beds?
    errors << 'Draw must have at least one bed per student; you should add '\
        'more suites or remove some students.'
  end

  def currently_valid?
    errors.empty?
  end

  def activate_draw
    return if draw.update(status: 'pre_lottery')
    errors << 'Draw update failed.'
  end

  def send_emails
    draw.students.each do |student|
      mailer.draw_invitation(student, college).deliver_later
    end
  end

  def success
    { object: draw, msg: { notice: 'Draw successfully initiated.' } }
  end

  def error
    {
      object: nil,
      msg: { error: "There was a problem initiating the draft:\n#{error_msgs}" }
    }
  end

  def error_msgs
    errors.join("\n")
  end
end
