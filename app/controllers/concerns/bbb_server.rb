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

require 'bigbluebutton_api'
require 'json'

module BbbServer
  extend ActiveSupport::Concern
  include BbbApi

  META_LISTED = "gl-listed"

  # Checks if a room is running on the BigBlueButton server.
  def room_running?(bbb_id)
    bbb_server.is_meeting_running?(bbb_id)
  end

  # Returns a list of all running meetings
  def all_running_meetings
    bbb_server.get_meetings
  end

  def get_recordings(meeting_id)
    bbb_server.get_recordings(meetingID: meeting_id)
  end

  def get_multiple_recordings(meeting_ids)
    bbb_server.get_recordings(meetingID: meeting_ids)
  end

  # Returns a URL to join a user into a meeting.
  def join_path(room, name, options = {}, uid = nil)
    # Create the meeting, even if it's running
    start_session(room, options)

    # Determine the password to use when joining.
    password = options[:user_is_moderator] ? room.moderator_pw : room.attendee_pw

    # Generate the join URL.
    join_opts = {}
    join_opts[:userID] = uid if uid
    join_opts[:join_via_html5] = true
    join_opts[:guest] = true if options[:require_moderator_approval] && !options[:user_is_moderator]

    if NeelzRoom.is_neelz_room?(room)
      neelz_room = NeelzRoom.convert_to_neelz_room(room)
      join_opts["userdata-bbb_show_participants_on_login"] = neelz_room.show_participants_on_login?
      join_opts["userdata-bbb_auto_swap_layout"]   = true
      join_opts["userdata-bbb_hide_presentation"] = true
    else
      join_opts["userdata-bbb_display_branding_area"] = true
      join_opts["userdata-bbb_custom_style_url"] = "https://konkret-mafo.cloud/konkret/bbb-html5.css".to_json
    end

    ##test magic_cap_user ...
    if name[0..3] === 'MCU_'
     join_opts["userdata-bbb_magic_cap_user"] = true
     if name[4..7] === 'MOD_'
      password = room.moderator_pw
      join_opts["userdata-bbb_magic_cap_user_visible_for_herself"] = true
     else
       join_opts["userdata-bbb_magic_cap_user_visible_for_moderator"] = true
     end
    end

    bbb_server.join_meeting_url(room.bbb_id, name, password, join_opts)
  end

  # Creates a meeting on the BigBlueButton server.
  def start_session(room, options = {})
    create_options = {
      record: options[:meeting_recorded].to_s,
      logoutURL: options[:meeting_logout_url] || '',
      logo: NeelzRoom.is_neelz_room?(room) ? '' : "https://konkret-mafo.cloud/konkret/logo_with_text2.png".to_json ,
      moderatorPW: room.moderator_pw,
      attendeePW: room.attendee_pw,
      moderatorOnlyMessage: options[:moderator_message],
      muteOnStart: options[:mute_on_start] || false,
      "meta_#{META_LISTED}": options[:recording_default_visibility] || false,
      "meta_bbb-origin-version": Greenlight::Application::VERSION,
      "meta_bbb-origin": Rails.configuration.instance_name,
      "meta_bbb-origin-server-name": options[:host]
    }

    create_options[:guestPolicy] = "ASK_MODERATOR" if options[:require_moderator_approval]

    # Send the create request.
    begin
      modules = BigBlueButton::BigBlueButtonModules.new
      modules.add_presentation(:file, '/usr/src/app/public/instance_default.pdf')
      #logger.info "MODULES = #{modules.to_xml}"
      #config_xml = bbb_server.get_default_config_xml
      #logger.info "DEF-CONFIG_XML = " + config_xml
      meeting = bbb_server.create_meeting(room.name, room.bbb_id, create_options, modules)
      # Update session info.
      unless meeting[:messageKey] == 'duplicateWarning'
       room.update_attributes(sessions: room.sessions + 1,
          last_session: DateTime.now)
      end
    rescue BigBlueButton::BigBlueButtonException => e
      puts "bigBLUE failed on create: #{e.key}: #{e.message}"
      raise e
    end
  end

  # Gets the number of recordings for this room
  def recording_count(bbb_id)
    bbb_server.get_recordings(meetingID: bbb_id)[:recordings].length
  end

  # Update a recording from a room
  def update_recording(record_id, meta)
    meta[:recordID] = record_id
    bbb_server.send_api_request("updateRecordings", meta)
  end

  # Deletes a recording from a room.
  def delete_recording(record_id)
    bbb_server.delete_recordings(record_id)
  end

  # Deletes all recordings associated with the room.
  def delete_all_recordings(bbb_id)
    record_ids = bbb_server.get_recordings(meetingID: bbb_id)[:recordings].pluck(:recordID)
    bbb_server.delete_recordings(record_ids) unless record_ids.empty?
  end
end
