ui_url = attribute(
    "ui_url",
    description: "UI URL"
)

require 'selenium-webdriver'

FileUtils.mkdir_p 'test/scr'

options = Selenium::WebDriver::Chrome::Options.new
options.add_argument('--ignore-certificate-errors')
options.add_argument('--disable-popup-blocking')
options.add_argument('--disable-translate')
driver = Selenium::WebDriver.for :chrome, options: options
driver.navigate.to "#{ui_url}/ui/servers"
sleep 2
driver.save_screenshot("test/scr/nomad_servers.png")
driver.navigate.to "#{ui_url}/ui/clients"
sleep 2
driver.save_screenshot("test/scr/nomad_clients.png")
driver.quit
