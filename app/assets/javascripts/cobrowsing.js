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
        }else{
          if (data.action === "unshare"){
            stopCoBrowsing();
          }else{
            if (data.action === "refresh"){
              processRefreshOffer();
            }
          }
        }
      }
    });
  }
});

let neelz_iFrames = [null, null];

let coBrowsingState = {
  blocked: false,
  refreshRequired: false,
  activeIFrame: 0,
  active: false,
  url: ''
};

let startCoBrowsing = function(url,readonly){

  coBrowsingState.active = true;
  coBrowsingState.url = url;

  console.log('url',url);
  console.log('CBS',coBrowsingState);
  console.log('NEELZ_IFRAMES',neelz_iFrames);


  let show_vp = function () {
    $('#curtain_layer').animate(
        {
          opacity: 0.0
        },1500,
        function () {
        }
    );
  };
  let set_url_vp = function () {
    neelz_iFrames[coBrowsingState.activeIFrame].attr('src',url);
    setTimeout(show_vp,1000);
  };

  $('#curtain_layer').animate(
      {
        opacity: 1.0
      }, 250,
      function () { //complete
        neelz_iFrames[coBrowsingState.activeIFrame].attr('src','');
        setTimeout(set_url_vp, 250);
      }
  );
};

let stopCoBrowsing = function(){
  coBrowsingState.active = false;

  $('#curtain_layer').animate(
      {
        opacity: 1.0
      }, 1000,
      function () { //complete
      }
  );

};

let refreshCoBrowsing = function () {
  if (coBrowsingState.active) {
    if (coBrowsingState.activeIFrame === 0) {
      neelz_iFrames[1].attr('src', '').attr('src', coBrowsingState.url);
      neelz_iFrames[1].css('pointer-events', 'all');
      neelz_iFrames[1].animate(
          {opacity: 1.0}, 1000,
          function () {
            coBrowsingState.activeIFrame = 1;
          }
      );
    } else {
      neelz_iFrames[0].attr('src', '').attr('src', coBrowsingState.url);
      neelz_iFrames[1].css('pointer-events', 'none');
      neelz_iFrames[1].animate(
          {opacity: 0.0}, 1000,
          function () {
            coBrowsingState.activeIFrame = 0;
          }
      );
    }
    coBrowsingState.refreshRequired = false;
    coBrowsingState.blocked = true;
  }
};

let processRefreshOffer = function () {
  if (coBrowsingState.active) {
    if (coBrowsingState.blocked) {
      coBrowsingState.refreshRequired = true;
    } else {
      refreshCoBrowsing();
    }
  }
};

let refreshJob = function(){
  if (coBrowsingState.active) {
    coBrowsingState.blocked = false;
    refreshCoBrowsing();
  }
};


$(document).ready(function () {
  neelz_iFrames[0] = $('#external_viewport_1');
  neelz_iFrames[1] = $('#external_viewport_2');
  setInterval(refreshJob, 5000);
});