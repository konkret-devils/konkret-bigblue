// BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
//
// Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
//
// This program is free software; you can redistribute it and/or modify it under the
// terms of the GNU Lesser General Public License as published by the Free Software
// Foundation; either version 3.0 of the License, or (at your option) any later
// version.
//
// BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
// PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License along
// with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

// Handle client request to join when meeting starts.
$(document).on("turbolinks:load", function(){
  let body = $("body"),
             controller = body.data('controller'),
             action = body.data('action');
  let bg = $('.background'),
      is_moderator = bg.attr('is_moderator') === 'yes';
  if(controller === "inside_room" && action === "inside" && !is_moderator){

    App.waiting = App.cable.subscriptions.create({
      channel: "CoBrowsingChannel",
      roomuid: bg.attr("room"),
      useruid: bg.attr("user")
    }, {
      connected: function() {
        console.log("connected");
      },

      disconnected: function(data) {
        console.log("disconnected");
        console.log(data);
      },

      rejected: function() {
        console.log("rejected");
      },

      received: function(data){
        console.log(data);
        if(data.action === "share"){
          startCoBrowsing(data.url,data.readonly==='1');
        }
      }
    });
  }
});

var startCoBrowsing = function(url,readonly){
  $('#glass_layer').css('opacity','0.65')
      .css('pointer-events','all');
  $('#external_viewport').attr('src','#');
  let show_vp = function () {
    $('#glass_layer').attr('opacity','0.0');
    if (!readonly){
      $('#glass_layer').css('pointer-events','none');
    }
  };
  let set_url_vp = function () {
    $('#external_viewport').attr('src',url);
    setTimeout(show_vp,3000);
  };
  setTimeout(set_url_vp, 500);
};
