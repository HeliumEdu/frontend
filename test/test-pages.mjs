import {Browser, Builder, until} from 'selenium-webdriver';
import * as chrome from 'selenium-webdriver/chrome.js';
import {expect} from 'chai';

let driver;

let options = new chrome.Options();
options.addArguments('--headless=new');
options.addArguments('--start-maximized');
options.addArguments('--disable-gpu');
options.addArguments('--no-sandbox');

describe('Pages Test', function () {
    beforeEach(async function () {
        driver = await new Builder()
            .forBrowser(Browser.CHROME)
            .setChromeOptions(options)
            .build();
    });

    afterEach(async function () {
        await driver.quit();
    });

    it('/ should load index', async function () {
        this.timeout(10000);

        await driver.get('http://localhost:3000/');

        await driver.wait(until.titleContains('Helium Student Planner'), 10000);

        const pageTitle = await driver.getTitle();

        expect(pageTitle).to.include('Helium Student Planner | Lightening Your Course Load');
    });
});
