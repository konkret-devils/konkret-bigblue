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
    elsif session['neelz_join_name']
      session['neelz_join_name']
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

    if room_running?(@room.bbb_id) || @room.owned_by?(current_user) || room_settings["anyoneCanStart"] || session[:neelz_role] === 'interviewer'

      # Determine if the user needs to join as a moderator.
      opts[:user_is_moderator] = @room.owned_by?(current_user) || room_settings["joinModerator"] || session[:neelz_role] === 'interviewer'

      opts[:require_moderator_approval] = room_settings["requireModeratorApproval"]
      opts[:mute_on_start] = room_settings["muteOnStart"]

      if current_user
        join_response = join_path(@room, current_user.name, opts, current_user.uid)
      else
        join_name = params[:join_name] || params[@room.invite_path][:join_name]
        join_name = join_name.strip
        if Rails.configuration.warn_participants_not_to_provide_fullname
          if join_name.include? ' '
            join_name = join_name[0..(join_name.index(' ')-1)]
          end
        end
        join_response = join_path(@room, join_name, opts)
      end

      bbb_url_returned = join_response #[:url]

      session['target_url_client'] = bbb_url_returned
      #session['current_room_inside'] = @room.uid
      #session['is_neelz_room'] = NeelzRoom.is_neelz_room?(@room)

      redirect_url = bbb_url_returned #'/inside'

      if NeelzRoom.is_neelz_room?(@room)
        #neelz_room = NeelzRoom.convert_to_neelz_room(@room)
        if session[:neelz_role] == 'interviewer'
          redirect_url = '/neelz/i_inside'
        elsif session[:neelz_role] == 'proband'
          redirect_url = '/neelz/p_inside'
        else
          return redirect_to('/', alert: 'invalid request')
        end
      end

      redirect_to redirect_url

      NotifyUserWaitingJob.set(wait: 5.seconds).perform_later(@room)

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
