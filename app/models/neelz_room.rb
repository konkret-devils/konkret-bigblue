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

class NeelzRoom < Room

  has_one :neelz_attributes

  def init_new
    self.neelz_attributes = NeelzAttributes.new
    self.neelz_attributes.room = self
  end

  def notify_co_browsing_share
    ActionCable.server.broadcast("#{self.uid}_co_browsing_channel",
                                 {action: "share", url: "#{get_proband_url}",
                                  readonly: "#{proband_readonly? ? '1' : '0'}"})
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

  def qvid
    neelz_attributes.qvid
  end

  def set_qvid(qvid_nr)
    neelz_attributes.qvid = qvid_nr
  end

  def set_updated_at(date_now)
    neelz_attributes.updated_at = date_now
  end

  def proband_url
    neelz_attributes.proband_url
  end

  def proband_readonly?
    neelz_attributes.proband_readonly
  end

  def set_proband_url(url)
    neelz_attributes.proband_url = url
  end

  def set_proband_readonly(readonly)
    neelz_attributes.proband_readonly = readonly
  end

  def interviewer_browses?
    neelz_attributes.interviewer_browses;
  end

  def proband_browses?
    neelz_attributes.proband_browses
  end

  def set_interviewer_browses(i_browses)
    neelz_attributes.interviewer_browses = i_browses
  end

  def set_proband_browses(c_browses)
    neelz_attributes.proband_browses = c_browses
  end

  def proband_alias
    neelz_attributes.proband_alias
  end

  def set_proband_alias(name)
    neelz_attributes.proband_alias = name
  end

  def co_browsing_externally_triggered?
    neelz_attributes.co_browsing_externally_triggered
  end

  def set_co_browsing_externally_triggered(ext_triggered)
    neelz_attributes.co_browsing_externally_triggered = ext_triggered
  end

end
