/**
 * getEnvironment - Returns the current environment, or dev by default
 * @returns {String}
 */
export const getEnvironment = () => process.env.NODE_ENV
    ? process.env.NODE_ENV
    : 'dev';


/**
 * getApiUrl  - Returns the URL for the api, given the current environment
 * @returns {String}
 */
export const getApiUrl = () => {
    switch (getEnvironment()) {
        case 'prod':
            return 'https://api.heliumedu.com';
        case 'test':
            return 'http://api-test.heliumedu.com';
        case 'dev':
        default:
            return 'http://localhost:8000';
    }
};


/**
 * getAppUrl  - Returns the URL for the app, given the environment
 * @returns {String}
 */
export const getAppUrl = () => {
    switch (getEnvironment()) {
        case 'prod':
            return 'http://app.heliumedu.com';
        case 'test':
            return 'http://app-test.heliumedu.com';
        case 'dev':
        default:
            return 'http://localhost:3000';
    }
};
