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

class CreateNeelzAttributes < ActiveRecord::Migration[5.0]
  def change
    create_table "neelz_attributes", force: :cascade do |t|
      t.integer "room_id", null: false
      t.integer "qvid", null: false
      t.string "interviewer_name"
      t.integer "interviewer_personal_nr"
      t.string "proband_alias", null: false
      t.boolean "interviewer_browses", null: false
      t.boolean "proband_browses", null: false
      t.string "interviewer_url"
      t.string "proband_url"
      t.boolean "proband_readonly"
      t.boolean "co_browsing_externally_triggered"
      t.integer "interviewer_screen_split_mode_on_login"
      t.integer "proband_screen_split_mode_on_login"
      t.integer "proband_screen_split_mode_on_share"
      t.integer "external_frame_min_width"
      t.datetime "updated_at", null: false
      t.index ["room_id"], name: "index_neelz_attributes_on_room_id", unique: true
      t.index ["qvid"], name: "index_neelz_attributes_on_qvid"
    end
  end
end
