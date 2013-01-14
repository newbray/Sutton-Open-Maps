function loadLayer(slug) {

  // Remove selected class from all buttons
  $('li[id^="button"]').removeClass('selected');

  // Highlight current button          
  $("#button-" + slug).addClass('selected');
  
  var myOptions = {
    zoom: 16,
    mapTypeId: google.maps.MapTypeId.ROADMAP
  };
  
  var map = new google.maps.Map(document.getElementById("map"),
      myOptions);
 
  var bounds = new google.maps.LatLngBounds();       

  var url = '/maps/' + slug + '.json';
  
  var windows = [];
  
  // Add user's location with HTML5 geolocation API
  
  if (navigator.geolocation) {
    console.log("Geolocation supported in this browser.")

    navigator.geolocation.getCurrentPosition(function(location){
      user_ll = new google.maps.LatLng(location.coords.latitude, location.coords.longitude);

      var user_marker = new google.maps.Marker({
        position: user_ll,
        map: map
      });

      var infowindow = new google.maps.InfoWindow({
        content: "<p><span class='info_title'>You are here</span></p>"
      });

      google.maps.event.addListener(user_marker, 'click', function() {
        $.each (windows, function() {
          this.close();
        });

        infowindow.open(map, user_marker);
        windows.push(infowindow);
      });

      bounds.extend(user_ll);
    });
  } else {
    console.log("Geolocation is not supported in this browser.")
  }
  
  // Fetch the data for the markers       
  $.get(
    url,
    function(data) {

      // Loop through each Place in the data and create a marker
      $.each (data['places'], function() {
        
        ll = new google.maps.LatLng(this.lat, this.lng);
        
        var marker = new google.maps.Marker({
          position: ll,
          title: this.title,
          map: map,
          icon: '/icons/' + data['icon']
        });
                        
        // Build content for info window
        var content = "<p><span class='info_title'>" + this.title + "</span>"
        
        if (this.address) {

          content += "<br />" + this.address
          
          if (this.phone) {
            content += "<br />Phone: " + this.phone
          }
        }
        
        content += "</p>"
        
        if (this.description) {
          content += "<p>" + this.description + "</p>"
        }
        
        var infowindow = new google.maps.InfoWindow({
          content: content,
          maxWidth: 600
        });
        
        // Click event handler for info window
        google.maps.event.addListener(marker, 'click', function() {

          // Remove other open info windows
          $.each (windows, function() {
            this.close();
          });

          infowindow.open(map, marker);
          windows.push(infowindow);
        });
        
        bounds.extend(ll);
      });

      // Display the map zoomed and centred on the user's location if we have it, otherwise zoom out to include all the POIs
      if (typeof user_ll != 'undefined') {
        map.setCenter(user_ll);
      } else {
        map.fitBounds(bounds);
      }
    }
  );

}
