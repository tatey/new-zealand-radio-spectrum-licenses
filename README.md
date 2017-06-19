# New Zealand TV Transmitter Data Scraper

This is a collection of super hacky scripts that scrapes all of the TV
transmitter data published by the [Radio Spectrum Management](https://www.rsm.govt.nz).

## System Dependencies

* [Ruby 2.4](https://www.ruby-lang.org)
* [Bundler](https://rubygems.org/gems/bundler)
* [Google Chrome](https://www.google.com/chrome/browser/desktop/index.html)

## Usage

Get all the TV transmitters:

    $ ./transmitters/createdb ~/Desktop/transmitters.sqlite
    $ ./transmitters/scrape ~/Desktop/transmitters.sqlite

Convert NZTOPO50 grid references into WGS85 (Latitude/Longitude) and get "area served":

    $ ./locations/createdb ~/Desktop/locations.sqlite
    $ ./transmitters/scrape ~/Desktop/transmitters.sqlite ~/Desktop/locations.sqlite
    $ ./transmitters/geocode ~/Desktop/locations.sqlite

## License

Licensed under the MIT license. See [LICENSE.txt](LICENSE.txt)
