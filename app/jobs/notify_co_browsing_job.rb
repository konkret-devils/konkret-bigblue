class NotifyCoBrowsingJob < ApplicationJob
  queue_as :default

  def perform(room)
    room.notify_co_browsing
  end
end