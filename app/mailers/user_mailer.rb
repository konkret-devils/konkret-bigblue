# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

class UserMailer < ApplicationMailer
  include ApplicationHelper
  include ThemingHelper

  default from: Rails.configuration.smtp_sender

  def verify_email(user, url, settings)
    @settings = settings
    @user = user
    @url = url
    @image = logo_image_email
    @color = user_color
    mail(to: @user.email, subject: tra('landing.welcome'))
  end

  def password_reset(user, url, settings)
    @settings = settings
    @user = user
    @url = url
    @image = logo_image_email
    @color = user_color
    mail to: user.email, subject: tra('reset_password.subtitle')
  end

  def user_promoted(user, role, url, settings)
    @settings = settings
    @url = url
    @admin_url = url + "admins"
    @image = logo_image_email
    @color = user_color
    @role = translated_role_name(role)
    mail to: user.email, subject: t('mailer.user.promoted.subtitle', role: translated_role_name(role), instance_name: inst_name)
  end

  def user_demoted(user, role, url, settings)
    @settings = settings
    @url = url
    @root_url = url
    @image = logo_image_email
    @color = user_color
    @role = translated_role_name(role)
    mail to: user.email, subject: t('mailer.user.demoted.subtitle', role: translated_role_name(role), instance_name: inst_name)
  end

  def invite_email(invitor, email, url, settings)
    @settings = settings
    @name = invitor.name
    @email = email
    @url = url
    @image = logo_image_email
    @color = user_color
    @from = "#{invitor.name} ~ via #{Rails.configuration.smtp_sender}"
    @reply_to = "#{invitor.name} <#{invitor.email}>"
    mail to: email, subject: tra('mailer.user.invite.subject'), from: @from, 'reply-to': @reply_to
  end

  def approve_user(user, url, settings)
    @settings = settings
    @user = user
    @url = url
    @image = logo_image_email
    @color = user_color
    mail to: user.email, subject: tra('mailer.user.approve.subject')
  end

  def approval_user_signup(user, url, admin_emails, settings)
    @settings = settings
    @user = user
    @url = url
    @image = logo_image_email
    @color = user_color

    mail to: admin_emails, subject: tra('mailer.user.approve.signup.subject')
  end

  def invite_user_signup(user, url, admin_emails, settings)
    @settings = settings
    @user = user
    @url = url
    @image = logo_image_email
    @color = user_color

    mail to: admin_emails, subject: tra('mailer.user.invite.signup.subject')
  end
end
