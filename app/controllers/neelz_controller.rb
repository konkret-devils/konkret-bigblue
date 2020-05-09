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

class NeelzController < ApplicationController
  include Pagy::Backend
  include Recorder
  include Joiner
  include Populator
  include Emailer

  # GET /neelz/gate
  def gate
    @cache_expire = 10.seconds
    session['neelz_qvid'] = params[:qvid].to_i(10)
    session['neelz_url_interviewer'] = params[:url_interviewer] if params[:url_interviewer]
    session['neelz_url_proband'] = params[:url_proband] if params[:url_proband]
    session['neelz_interviewer_personal_nr'] = params[:interviewer_personal_nr]
    session['neelz_interviewer_name'] = params[:interviewer_name]
    session['__join_name'] = params[:interviewer_name]
    session['neelz_proband_readonly'] = true if params[:proband_readonly]
    session['neelz_name_of_study'] = params[:studie_name]
    @neelz_room = get_room
    session['neelz_room_uid'] = @neelz_room.uid
    session['neelz_room_access_code'] = @neelz_room.access_code
    session[:access_code] = @neelz_room.access_code
    session['neelz_proband_qvid'] = qvid_proband_encoded
    cookies.encrypted[:greenlight_name] = params[:interviewer_name]
    redirect_to '/neelz'
  end

  # GET /neelz/cgate/:proband_qvid
  def cgate
    @cache_expire = 10.seconds
    session['neelz_qvid'] = decode_proband_qvid(params[:proband_qvid])
    @neelz_room = get_room
    return redirect_to('/', alert: 'Raum nicht auffindbar') unless @neelz_room
    session['neelz_room_uid'] = @neelz_room.uid
    session['neelz_proband_qvid'] = qvid_proband_encoded
    session['__join_name'] = @neelz_room.attendee_pw[12..-1]
    redirect_to '/'+@neelz_room.uid
  end

  # GET /neelz
  def preform
    @cache_expire = 10.seconds
    @neelz_interviewer_name = session['neelz_interviewer_name']
    @neelz_name_of_study = session['neelz_name_of_study']
    @neelz_proband_access_url = proband_access_url
    @neelz_room_access_code = session['neelz_room_access_code']
    @neelz_proband_name = session['neelz_proband_name'] || ''
    @neelz_proband_email = session['neelz_proband_email'] || ''
  end

  # POST /neelz/waiting
  def waiting
    @cache_expire = 10.seconds
    @neelz_proband_name = params[:session][:name_proband]
    @neelz_proband_email = params[:session][:email_proband]
    @room = get_room
    return redirect_to '/neelz' unless @room
    session['neelz_proband_name'] = @neelz_proband_name
    session['neelz_proband_email'] = @neelz_proband_email
    @room.attendee_pw = @room.attendee_pw[0..11] + @neelz_proband_name
    @neelz_proband_access_url = proband_access_url
    @neelz_room_access_code = session[:access_code]
    @neelz_interviewer_name = session['neelz_interviewer_name']
    @neelz_name_of_study = session['neelz_name_of_study']
    send_neelz_participation_email(@neelz_proband_email,@neelz_proband_access_url,
                                   @neelz_room_access_code,@neelz_interviewer_name,
                                   @neelz_proband_name,@neelz_name_of_study)
  end

  private

  def get_room
    #find function user
    @neelz_user = User.include_deleted.find_by(email: Rails.configuration.neelz_email)
    if @neelz_user
      room_uid = 'kon-survey-' + qvid_interviewer_encoded
      @neelz_room = Room.include_deleted.find_by(uid: room_uid)
      @neelz_room = create_room(@neelz_user) unless @neelz_room
      @neelz_room
    end
  end

  def create_room(owner)
    room_uid = 'kon-survey-' + qvid_interviewer_encoded
    room = Room.new(name: session['neelz_name_of_study'] + ' - Interview #' + qvid_proband_encoded)
    room.uid = room_uid
    room.owner = owner
    room.access_code = rand(10000...99999).to_s
    room.room_settings = create_room_settings_string
    room.save
    room
  end

  def create_room_settings_string
    room_settings = {
        "muteOnStart": false,
        "requireModeratorApproval": false,
        "anyoneCanStart": true,
        "joinModerator": true
    }
    room_settings.to_json
  end

  def qvid_interviewer_encoded
    val = (session['neelz_qvid'] + 93) * 2 + 11
    val.to_s(36)
  end

  def qvid_proband_encoded
    val = (session['neelz_qvid'] + 117) * 3 + 213
    'k' + val.to_s(24)
  end

  def decode_proband_qvid(proband_qvid)
    p_qvid = proband_qvid[1..-1].to_i(24)
    ((p_qvid - 213) / 3) - 117
  end

  def proband_access_url
    Rails.configuration.instance_url + 'neelz/cgate/' + session['neelz_proband_qvid']
  end

end
