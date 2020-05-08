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

  # GET /neelz/gate
  def gate
    co_browsing_url = params[:u]
    interviewer_name = params[:i]
    name_of_study = params[:s]
    session['neelz_co_browsing_url'] = co_browsing_url
    session['neelz_interviewer_name'] = interviewer_name
    session['neelz_name_of_study'] = name_of_study
    redirect_to '/neelz/'
  end

  # GET /neelz/
  def preform
    @cache_expire = 10.seconds
    @neelz_co_browsing_url = session['neelz_co_browsing_url']
    @neelz_interviewer_name = session['neelz_interviewer_name']
    @neelz_name_of_study = session['neelz_name_of_study']
  end

end
