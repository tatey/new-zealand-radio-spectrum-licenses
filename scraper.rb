require "byebug"
require "capybara/poltergeist"
require "scraperwiki"

VERSION = "0.0.2"

Capybara.register_driver :poltergeist_with_suppressed_logger do |app|
  Capybara::Poltergeist::Driver.new(app, phantomjs_logger: StringIO.new)
end

@session = Capybara::Session.new(:poltergeist_with_suppressed_logger)
@session.driver.headers = {"User-Agent" => "Morph.io Scraper https://github.com/tatey/new-zealand-radio-spectrum-licenses (Scaper #{VERSION}) (Ruby #{RUBY_VERSION}/#{RUBY_PLATFORM})"}
@logger = Logger.new(STDOUT)

@licences = {}

def scrape_search_page(licence_type)
  @logger.info "Scraping search page for licence type #{licence_type}"

  @session.visit("https://www.rsm.govt.nz/smart-web/smart/page/-smart/domain/licence/SelectLicencePage.wdk?showExit=Yes")
  @session.find("select[title=\"Licence Type\"]").select(licence_type)
  @session.find(".formButton[title=Search]").click # Search
end

def scrape_list_page
  @session.find(".listTable").all("tbody tr")[1..-1].map do |tr|
    tr.all("td").map(&:text)
  end.each do |values|
    licence_id = values[0]
    frequency = values[4]
    data = {
      licence_id: licence_id,
      licence_no: values[1],
      licence_type: values[7],
      licensee: values[2],
      channel: values[3],
      frequency: frequency,
      location: values[5],
      grid_reference: values[6],
      status: values[8],
    }

    unless @licences[licence_id]
      @licences[licence_id] = scrape_detail_page(licence_id)
    end
    data.merge!(@licences[licence_id][frequency] || {})
    ScraperWiki.save_sqlite([:licence_id, :frequency], data)
  end
end

def scrape_detail_page(licence_id)
  @logger.info "Scraping detail page for licence ID #{licence_id}"

  data = {}
  @session.all("a", text: licence_id).first.click
  @session.all(".listTable")[0].all("tbody tr")[1..-1].each do |tr|
    values = tr.all("td").map(&:text)
    data[values[4]] = {
      power: values[5],
      polarisation: values[7],
    }
  end
  @session.all(".button[title=Back]").first.click # Back
  data
end

[
  "UHF TV <10dBW (Spectrum)",
  "UHF TV >=10 & <30dBW (Spectrum)",
  "UHF TV >=30 & <40dBW (Spectrum)",
  "UHF TV >=40 & <50dBW (Spectrum)",
  "UHF TV >=50dBW (Spectrum)",
  "VHF FM <10dBW (Spectrum)",
  "VHF FM >=10 & <20dBW (Spectrum)",
  "VHF FM >=20 & <30dBW (Spectrum)",
  "VHF FM >=30 & <40dBW (Spectrum)",
  "VHF FM >=40dBW (Spectrum)",
  "VHF TV <10dBW (Spectrum)",
  "VHF TV >=10 & < 30dBW (Spectrum)",
  "VHF TV >=30 & <50dBW (Spectrum)",
  "VHF TV >=50dBW (Spectrum)",
].each do |licence_type|
  scrape_search_page(licence_type)
  loop do
    scrape_list_page
    next_button = @session.all(".formButton[title=\"Next Page\"]")&.first
    if next_button
      next_button.click
    else
      break
    end
  end
end
