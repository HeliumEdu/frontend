import { Builder, Browser, By, until } from 'selenium-webdriver';
import * as chrome from 'selenium-webdriver/chrome.js';
import chromedriver from 'chromedriver';
import { expect } from 'chai';

var driver;

let chromeOptions = new chrome.Options();
chromeOptions.addArguments('--headless');
chromeOptions.addArguments('--start-maximized');
chromeOptions.addArguments('--no-sandbox');

describe('Pages Test', function() {
  beforeEach(async function() {
    driver = await new Builder()
      .forBrowser(Browser.CHROME)
      .setChromeOptions(chromeOptions)
      .build();
  });

  afterEach(async function() {
    await driver.quit();
  });

  it('should load /tour', async function() {
    this.timeout(10000);

    await driver.get('http://localhost:3000/');

    await driver.wait(until.titleContains('Helium Student Planner'), 10000);

    const pageTitle = await driver.getTitle();

    expect(pageTitle).to.include('Helium Student Planner | Lightening Your Course Load');
  });
});
