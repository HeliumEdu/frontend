const localStorageMock = (function() {
  let store = {};
  return {
    getItem: function(key) {
      return store[key] || null;
    },
    setItem: function(key, value) {
      store[key] = value.toString();
    },
    clear: function() {
      store = {};
    },
    removeItem: function(key) {
      delete store[key];
    }
  };
})();
global.localStorage = localStorageMock;

const cookiesMock = (function() {
  let store = {};
  return {
    get: function(key) {
      return store[key] || null;
    },
    set: function(key, value) {
      store[key] = value.toString();
    },
    clear: function() {
      store = {};
    },
    delete: function(key) {
      delete store[key];
    }
  };
})();
global.Cookies = cookiesMock;

const { JSDOM } = require('jsdom');
const { window } = new JSDOM('<!doctype html><html><body></body></html>', {
    url: "http://localhost:3000/"
});

const $ = require('jquery')(window);
global.$ = $;
global.jQuery = $;

global.window = window;
global.document = window.document;

global.location = {
    href: 'http://localhost:3000/',
    host: 'localhost:3000',
    protocol: 'http:'
};

const fs = require('fs');
const path = require('path')

const scriptContent = fs.readFileSync(path.resolve(__dirname, '../src/assets/js/base.js'), 'utf8');
dom = new JSDOM(`<!DOCTYPE html><html><body><div id="app"></div></body></html>`, {
    runScripts: "dangerously",
});
document = dom.window.document;
const scriptElement = document.createElement('script');
scriptElement.textContent = scriptContent;
document.body.appendChild(scriptElement);

dom.window.addEventListener('DOMContentLoaded', () => {
    global.helium = new Helium();
});
