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

require 'bbb_api'

class Room < ApplicationRecord
  include Deleteable

  before_create :setup

  validates :name, presence: true

  belongs_to :owner, class_name: 'User', foreign_key: :user_id
  has_many :shared_access

  def self.admins_search(string)
    active_database = Rails.configuration.database_configuration[Rails.env]["adapter"]
    # Postgres requires created_at to be cast to a string
    created_at_query = if active_database == "postgresql"
      "created_at::text"
    else
      "created_at"
    end

    search_query = "rooms.name LIKE :search OR rooms.uid LIKE :search OR users.email LIKE :search" \
    " OR users.#{created_at_query} LIKE :search"

    search_param = "%#{string}%"

    where(search_query, search: search_param)
  end

  def self.admins_order(column, direction)
    # Include the owner of the table
    table = joins(:owner)

    return table.order(Arel.sql("rooms.#{column} #{direction}")) if table.column_names.include?(column)

    return table.order(Arel.sql("#{column} #{direction}")) if column == "users.name"

    table
  end

  # Determines if a user owns a room.
  def owned_by?(user)
    user_id == user&.id
  end

  def shared_users
    User.where(id: shared_access.pluck(:user_id))
  end

  def shared_with?(user)
    return false if user.nil?
    shared_users.include?(user)
  end

  # Determines the invite path for the room.
  def invite_path
    "#{Rails.configuration.relative_url_root}/#{CGI.escape(uid)}"
  end

  # Notify waiting users that a meeting has started.
  def notify_waiting
    logger.info("room :: notify_waiting .. #{self.uid}")
    ActionCable.server.broadcast("#{self.uid}_waiting_channel", action: "started")
  end

  def is_neelz_room?
    self.uid && self.uid[0..10] == 'kon-survey-'
  end

  def notify_co_browsing_share
    ActionCable.server.broadcast("#{self.uid}_co_browsing_channel", {action: "share", url: "#{get_proband_url}", readonly: "#{proband_readonly? ? '1' : '0'}"})
  end

  def notify_co_browsing_unshare
    ActionCable.server.broadcast("#{self.uid}_co_browsing_channel", {action: "unshare"})
  end

  def notify_co_browsing_refresh
    ActionCable.server.broadcast("#{self.uid}_co_browsing_channel", {action: "refresh"})
  end

  def notify_co_browsing_thank_you
    ActionCable.server.broadcast("#{self.uid}_co_browsing_channel", {action: "thank_you"})
  end

  def get_attendee_pw
    self.attendee_pw
  end

  def get_moderator_pw
    self.moderator_pw
  end

  def set_attendee_pw(password)
    self.attendee_pw = password
  end

  def set_moderator_pw(password)
    self.moderator_pw = password
  end

  def get_proband_url
    get_moderator_pw[13..-1]
  end

  def proband_readonly?
    get_moderator_pw[12].to_i(10) == 1
  end

  def set_proband_url(url)
    set_moderator_pw(get_moderator_pw[0..12]+url)
  end

  def set_proband_readonly(readonly)
    if readonly
      ro = '1'
    else
      ro = '0'
    end
    set_moderator_pw(get_moderator_pw[0..11] + ro + get_moderator_pw[13..-1])
  end

  def interviewer_browses?
    get_attendee_pw[12].to_i(10) == 1
  end

  def proband_co_browses?
    get_attendee_pw[13].to_i(10) == 1
  end

  def set_interviewer_browses(i_browses)
    if i_browses
      ib = '1'
    else
      ib = '0'
    end
    set_attendee_pw(get_attendee_pw[0..11] + ib + get_attendee_pw[13..-1])
  end

  def set_proband_co_browses(c_co_browses)
    if c_co_browses
      cb = '1'
    else
      cb = '0'
    end
    set_attendee_pw(get_attendee_pw[0..12] + cb + get_attendee_pw[14..-1])
  end

  def get_proband_name
    get_attendee_pw[14..-1]
  end

  def set_proband_name(name)
    set_attendee_pw(get_attendee_pw[0..13] + name)
  end

  # Generates a uid for the room and BigBlueButton.
  def setup
    self.uid = random_room_uid unless self.uid
    self.bbb_id = Digest::SHA1.hexdigest(Rails.application.secrets[:secret_key_base] + Time.now.to_i.to_s).to_s
    self.moderator_pw = RandomPassword.generate(length: 12) unless self.moderator_pw
    self.attendee_pw = RandomPassword.generate(length: 12) unless self.attendee_pw
  end

  private

  # Generates a three character uid chunk.
  def uid_chunk
    charset = ("a".."z").to_a - %w(b i l o s) + ("2".."9").to_a - %w(5 8)
    (0...3).map { charset.to_a[rand(charset.size)] }.join
  end

  # Generates a random room uid that uses the users name.
  def random_room_uid
    [owner.name_chunk, uid_chunk, uid_chunk].join('-').downcase
  end
end
