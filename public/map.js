      
      function loadLayer(slug) {
      
        // Remove selected class from all buttons
        $('li[id^="button"]').removeClass('selected');

        // Highlight current button          
        $("#button-" + slug).addClass('selected');
      
        var ll = new google.maps.LatLng(51.3604, -0.1902);
        
        var myOptions = {
          zoom: 13,
          center: ll,
          mapTypeId: google.maps.MapTypeId.ROADMAP
        };
        
        var map = new google.maps.Map(document.getElementById("map"),
            myOptions);
       
        var bounds = new google.maps.LatLngBounds();       

        var url = '/maps/' + slug + '.json';
        
/*         alert(url); */
        
        var windows = [];
               
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
            
            
            map.fitBounds(bounds);
            
          }
        );

      }
