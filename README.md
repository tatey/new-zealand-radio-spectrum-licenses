# A morph.io scraper for getting NZ TV transmitter data

This is a scraper that runs on
[morph.io](https://morph.io/tatey/new-zealand-radio-spectrum-licenses). It
fetches all of the TV transmitter data published by the [New Zealand Radio
Spectrum Management](https://www.rsm.govt.nz/smart-web/smart/page/-smart/domain/licence/SelectLicencePage.wdk?showExit=Yes).

![](schema.png)

## System Dependencies

* [Ruby 2.3](https://www.ruby-lang.org)
* [Bundler](https://rubygems.org/gems/bundler)
* [PhantomJS](http://phantomjs.org)

## Usage

Install the scraper's dependencies:

    $ bundle

Run the scraper:

    $ ./bin/scrape

The scraper will perform a search and then scrape each of the licences into
a SQLite database named `data.sqlite`.
