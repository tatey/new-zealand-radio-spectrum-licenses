require "byebug"
require "capybara/poltergeist"
require "scraperwiki"

VERSION = "0.0.1"

@session = Capybara::Session.new(:poltergeist)
@session.driver.headers = {"User-Agent" => "Morph.io Scraper https://github.com/tatey/new-zealand-radio-spectrum-licenses (Scaper #{VERSION}) (Ruby #{RUBY_VERSION}/#{RUBY_PLATFORM})"}
@logger = Logger.new(STDOUT)

@page = 0
@licences = {}

def scrape_search_page
  @logger.info "Scraping search page..."

  @session.visit("https://www.rsm.govt.nz/smart-web/smart/page/-smart/domain/licence/SelectLicencePage.wdk?showExit=Yes")
  districts_select = @session.find("#multi-district-select", visible: false)
  districts_select.all("option", visible: false).each do |district_option|
    text = district_option.text(:all)
    if !["New Zealand", "Overseas"].include?(text)
      districts_select.select(text, visible: false)
    end
  end
  @session.find(".formButton[title=Search]").click # Search
end

def scrape_list_page
  @logger.info "Scraping page #{@page += 1}..."

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
  @logger.info "Scraping detail page for licence #{licence_id}..."

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

scrape_search_page
loop do
  scrape_list_page
  next_button = @session.all(".formButton[title=\"Next Page\"]").first
  if next_button
    next_button.click
  else
    @logger.info "<peon>Job done</peon>"
    break
  end
end
