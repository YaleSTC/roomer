# frozen_string_literal: true

# Mailer class for student e-mails
class StudentMailer < ApplicationMailer
  # Send initial invitation to students in a draw
  #
  # @param user [User] the user to send the invitation to
  # @param college [College] the college to pull settings from
  def draw_invitation(user:, college: nil)
    determine_college(college)
    @user = user
    @intent_locked = user.draw.intent_locked
    @intent_deadline = format_date(user.draw.intent_deadline)
    mail(to: @user.email, subject: 'The housing process has begun',
         reply_to: @college.admin_email)
  end

  # Send invitation to a group leader to select a suite
  #
  # @param user [User] the group leader to send the invitation to
  # @param college [College] the college to pull settings from
  def selection_invite(user:, college: nil)
    determine_college(college)
    @user = user
    mail(to: @user.email, subject: 'Time to select a suite!',
         reply_to: @college.admin_email)
  end

  # Send notification to a user that their group was deleted
  #
  # @param user [User] the group leader to send the notification to
  # @param college [College] the college to pull settings from
  def disband_notification(user:, college: nil)
    determine_college(college)
    @user = user
    mail(to: @user.email, subject: 'Your housing group has been disbanded',
         reply_to: @college.admin_email)
  end

  # Send notification to a user that their group is finalizing
  #
  # @param user [User] the group leader to send the notification to
  # @param college [College] the college to pull settings from
  def finalizing_notification(user:, college: nil)
    return unless user.group
    determine_college(college)
    @user = user
    @finalizing_url = finalizing_url_for(@user)
    mail(to: @user.email, subject: 'Confirm your housing group',
         reply_to: @college.admin_email)
  end

  # Send notification to a leader that a user joined their group
  #
  # @param user [User] the group leader to send the notification to
  # @param college [College] the college to pull settings from
  def joined_group(joined:, group:, college: nil)
    determine_college(college)
    @user = group.leader
    @joined = joined
    mail(to: @user.email, subject: "#{joined.full_name} has joined your group",
         reply_to: @college.admin_email)
  end

  # Send notification to a leader that a user left their group
  #
  # @param user [User] the group leader to send the notification to
  # @param college [College] the college to pull settings from
  def left_group(left:, group:, college: nil)
    determine_college(college)
    @user = group.leader
    @left = left
    mail(to: @user.email, subject: "#{left.full_name} has left your group",
         reply_to: @college.admin_email)
  end

  # Send notification to a user that their group is locked
  #
  # @param user [User] the group leader to send the notification to
  # @param college [College] the college to pull settings from
  def group_locked(user:, college: nil)
    determine_college(college)
    @user = user
    mail(to: @user.email, subject: 'Your housing group is now locked',
         reply_to: @college.admin_email)
  end

  # Send reminder to submit housing intent to a user
  #
  # @param user [User] the student to send the reminder to
  # @param college [College] the college to pull settings from
  def intent_reminder(user:, college: nil)
    determine_college(college)
    @user = user
    @intent_date = format_date(user.draw.intent_deadline)
    mail(to: @user.email, subject: 'Reminder to submit housing intent',
         reply_to: @college.admin_email)
  end

  # Send reminder to lock housing group to a user
  #
  # @param user [User] the student to send the reminder to
  # @param college [College] the college to pull settings from
  def locking_reminder(user:, college: nil)
    determine_college(college)
    @user = user
    @locking_date = format_date(user.draw.locking_deadline)
    mail(to: @user.email, subject: 'Reminder to lock housing group',
         reply_to: @college.admin_email)
  end

  private

  def determine_college(college)
    @college = college || College.current
  end

  def format_date(date)
    return false unless date.present?
    date.strftime('%B %e')
  end

  def finalizing_url_for(user)
    if user.group.draw.present?
      draw_group_url(user.draw, user.group, host: @college.host)
    else
      group_url(user.group, host: @college.host)
    end
  end
end
