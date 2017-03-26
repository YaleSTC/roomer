# frozen_string_literal: true
#
# Class to enqueue reminder email jobs
class ReminderQueuer
  # Create new instance of ReminderQueuer, call #queue on it
  def self.queue(**params)
    new(**params).queue
  end

  # Initialize a new ReminderQueuer
  #
  # @param draw [Draw] the draw to send reminder emails in
  # @param type [String] type of email to send; must be "intent" or "locking"
  def initialize(draw:, type:)
    @draw = draw
    @type = type
  end

  # Queue the email job
  def queue
    draw.update!(email_type: type, last_email_sent: Time.zone.now)
    queue_job
    success
  rescue ActiveRecord::RecordInvalid => e
    error(e)
  rescue ArgumentError => e
    error(e.message)
  end

  private

  attr_reader :draw, :type

  # NOTE: this happens in the transaction
  def queue_job
    case type
    when 'intent'
      IntentReminderJob.perform_later(draw: draw)
    when 'locking'
      LockingReminderJob.perform_later(draw: draw)
    else
      raise ArgumentError, 'Invalid reminder type'
    end
  end

  def success
    {
      object: @draw,
      msg: { notice: "Sent #{type} reminders." }
    }
  end

  def error(error)
    {
      object: @draw,
      msg: { error: "Error sending #{type} reminders: #{error}." }
    }
  end
end
