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

module Joiner
  extend ActiveSupport::Concern

  # Displays the join room page to the user
  def show_user_join
    # Get users name
    @name = if current_user
      current_user.name
    elsif session['__join_name']
      session['__join_name']
    elsif cookies.encrypted[:greenlight_name]
      cookies.encrypted[:greenlight_name]
    else
              ""
    end

    @search, @order_column, @order_direction, pub_recs =
      public_recordings(@room.bbb_id, params.permit(:search, :column, :direction), true)

    @pagy, @public_recordings = pagy_array(pub_recs)

    render :join
  end

  # create or update cookie to track the three most recent rooms a user joined
  def save_recent_rooms
    if current_user
      recently_joined_rooms = cookies.encrypted["#{current_user.uid}_recently_joined_rooms"].to_a
      cookies.encrypted["#{current_user.uid}_recently_joined_rooms"] =
        recently_joined_rooms.prepend(@room.id).uniq[0..2]
    end
  end

  def join_room(opts)
    room_settings = JSON.parse(@room[:room_settings])

    if room_running?(@room.bbb_id) || @room.owned_by?(current_user) || room_settings["anyoneCanStart"] || session["is_moderator"]

      # Determine if the user needs to join as a moderator.
      opts[:user_is_moderator] = @room.owned_by?(current_user) || room_settings["joinModerator"] || session["is_moderator"]

      opts[:require_moderator_approval] = room_settings["requireModeratorApproval"]
      opts[:mute_on_start] = room_settings["muteOnStart"]

      if current_user
        join_response = join_meeting(@room, current_user.name, opts, current_user.uid)
      else
        join_name = params[:join_name] || params[@room.invite_path][:join_name]
        join_response = join_meeting(@room, join_name, opts)
      end

      bbb_url_returned = join_response #[:url]

      session['target_url_client'] = bbb_url_returned
      session['current_room_inside'] = @room.uid

      redirect_to '/inside'

    else
      search_params = params[@room.invite_path] || params
      @search, @order_column, @order_direction, pub_recs =
        public_recordings(@room.bbb_id, search_params.permit(:search, :column, :direction), true)

      @pagy, @public_recordings = pagy_array(pub_recs)

      # They need to wait until the meeting begins.
      render :wait
    end
  end

  def incorrect_user_domain
    Rails.configuration.loadbalanced_configuration && @room.owner.provider != @user_domain
  end

  # Default, unconfigured meeting options.
  def default_meeting_options
    invite_msg = tra("invite_message")
    {
      user_is_moderator: false,
      meeting_logout_url: request.base_url + logout_room_path(@room),
      meeting_recorded: true,
      moderator_message: "#{invite_msg}\n\n#{request.base_url + room_path(@room)}",
      host: request.host,
      recording_default_visibility: @settings.get_value("Default Recording Visibility") == "public"
    }
  end
end
