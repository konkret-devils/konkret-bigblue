class InsideRoomController < ApplicationController
  include Registrar

  # GET /inside
  def inside
    @cache_expire = 10.seconds
    @target_url_client = session['target_url_client']
  end

end
