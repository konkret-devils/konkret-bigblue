class InsideRoomController < ApplicationController
  include Registrar

  # GET /inside
  def inside
    @cache_expire = 10.seconds
    @target_url_client = session['target_url_client']
    @current_room_inside = session['current_room_inside']
    @is_neelz_room = session['is_neelz_room']
    @is_moderator = @is_neelz_room && session['is_moderator'] && session['moderator_for'] == @current_room_inside
  end

end
