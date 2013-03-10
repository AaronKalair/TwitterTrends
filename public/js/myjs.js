// Global variable representing  the side the next image needs to go on, 0 = left, 1 = right
var side = 0;

// When the submit button is pressed handle it
$('#myform').submit(function(event) {
  //  Prevent the form from submitting and resetting the page
  event.preventDefault();

  // Remove the form
  $('#myform').remove();

  // Insert a loading spinner
  $(".span5").canvasLoader({
    'radius':200,
    'dotRadius':10,
    'backgroundColor':'transparent',
    'className':'span5',
    'id':'canvasLoader1',
    'fps':8
  });

  // Build the query URL
  // Get the parameters from the form
  var vals = this.elements;
  var url = "/start?lat=" + vals["0"].value + "&lng=" + vals["1"].value + "&radius=" + vals["2"].value;

  // Make a call to the server for the trends
  jQuery.getJSON(url, function(content) {
    // Once we enter this callback we will have the data
    // Remove the loading spinner
    $('#canvasLoader1').remove();
    // Insert the center element
    $('<div class=span5 style="text-align:center; word-wrap:break-word;"> </div>').insertAfter($("#left"));

    // For each keyword returned
    for (var key in content) {
      // if its not an inherited property add the trend to the page
      if (content.hasOwnProperty(key)) {
        insertTrend(content[key]);
      }
    }
  });

  // Recall the server every x seconds
  setInterval(getTrends, 10000);
  setInterval(getImages, 20000);

});

// Make a query to the server for the latest 5 trending words
function getTrends() {
  jQuery.getJSON("/gettrends", function(content) {
    // Delete the current trends
    $(".span5").empty();

    // For every trend returned
    for (var key in content) {
      // If its not an inherited property add it to the page
      if (content.hasOwnProperty(key)) {
        insertTrend(content[key]);
      }
    }

  });
}

// Get the new 2 images from the server
function getImages() {
  jQuery.getJSON("/getimages", function(content) {

    // For every trend returned
    for (var key in content) {
      // If its not an inherited property add it to the page
      if (content.hasOwnProperty(key)) {
        if(side == 0) {
          // Insert the image on the left
          $("#left").empty();
          $("#left").append("<img src=" + content[key] + " />");
          side = 1;
        }
        else if(side == 1) {
          // Insert the image on the right
          $("#right").empty();
          $("#right").append("<img src=" + content[key] + " />");
          side = 0;
        }

      }
    }

  });
}

// Insert a word into the center element
function insertTrend(word) {
  $(".span5").append("<h1>" + word + "</h1>");
  $(".h1").text(word);
}

// Get the users location from the o/s
function getLocation() {
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(insertPosition);
  }
}

// Insert the users position into the form
function insertPosition(position) {
  $('#lat')["0"].value = position.coords.latitude.toFixed(2);
  $('#lng')["0"].value = position.coords.longitude.toFixed(2);
}

// Once the document is ready try to get their location
$(document).ready(function() {
  getLocation();
});

