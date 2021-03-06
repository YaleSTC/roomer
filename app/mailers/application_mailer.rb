# frozen_string_literal: true

#
# Base Mailer class
class ApplicationMailer < ActionMailer::Base
  default from: ->() { vesta_sender }
  layout 'mailer'
  helper :mail

  def mail(**params)
    text = ActionController::Base.helpers.strip_tags(render).strip
    super(**params) do |format|
      format.text { text }
      format.html { render }
    end
  end

  private

  def vesta_sender
    address = Mail::Address.new env('MAILER_FROM')
    address.display_name = env('MAILER_FROM_NAME') if env?('MAILER_FROM_NAME')
    address.format
  end

  def current_college
    @college ||= College.current
  end
end
