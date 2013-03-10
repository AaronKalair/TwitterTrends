Hyperlocal Twitter Trends
================

Determine the trending topics on Twitter for any specified area!

This tool will determine what keywords and terms appear most in any specified area as well as extracting the images in those tweets and showing them to you.

Although the goal of the project was to do it for really small areas like sports stadiums it can be used for any sized areas.

Note that the trends only seem to be meaningful in small areas if events are happening there.

Initally the 100 latest posts from the area specified will be used to extract keywords then live tweets will be captured.

Usage
====
Enter your credentials for [Twitter](https://dev.twitter.com/apps/new), [Alchemy](http://www.alchemyapi.com/api/register.html) and [Instagram](http://instagram.com/developer/clients/manage/) in the jacob/MyConfig.rb file

Enter your credentials for bit.ly [a legacy API key](https://bitly.com/a/settings/advanced) in the jacob/url_expander_credentials.yml file

Install the required gems with bundle install

Launch the server with ruby server.rb

Navigate to localhost:4567

The latitude and longitude field will be autopopulated using the geolocation API if allowed, replace the values in this field with the center point of the area you want  trends from
Enter the radius of the bounding box your trends will come from in the radius field

Examples
======
[The Twickenham Stadium during the England vs France Rugy Game](http://i.imgur.com/DzcLT4b.png)

[The Etihad Stadium during the Manchester City vs Chelsea Football Game](http://i.imgur.com/IS7fgWD.png)
