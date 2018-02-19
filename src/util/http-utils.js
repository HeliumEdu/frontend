import axios from "axios";
import _ from "lodash";
import {getApiUrl} from "./environment-utils";
import {getCookie} from "./cookie-utils";
import {PENDING, SUCCESS, POST, PUT, PATCH, GET, DELETE} from "./redux-constants";

const API_URL = getApiUrl();


const httpRequest = async(dispatch, requestType = GET, actionType = '', opts = {}) => {
    try {
        dispatch({
            type: actionType,
            meta: {status: PENDING}
        });

        const reqArgs = [`${API_URL}/${opts.endpoint || ''}`];

        // Add a data payload to the request if it's a POST or PUT
        if (requestType === POST || requestType === PUT || requestType === PATCH) {
            reqArgs.push(opts.data || {});
        }

        // Add Authorization header if the request needs to be authenticated, else add an empty object
        reqArgs.push(
            opts.requiresAuth
                ? {headers: {Authorization: `Token ${getCookie('token')}`}}
                : {},
        );


        const response = await axios[requestType](...reqArgs);

        dispatch({
            type: actionType,
            meta: {status: SUCCESS},
            payload: response.data
        });

        return Promise.resolve(response.data);
    } catch (err) {
        // Transpose the error from expected backend structures to a consistent frontend structure
        if (_.has(err, 'response.data.detail')) {
            err.response.data.errors = [{'error': _.get(err, 'response.data.detail')}];
        } else if (_.has(err, 'response.data.non_field_errors')) {
            err.response.data.errors = [];
            _.each(_.get(err, 'response.data.non_field_errors'), function (value) {
                err.response.data.errors.push({'error': value});
            });
        } else if (_.get(err, 'response.status') === 400) {
            err.response.data.errors = [];
            _.each(_.get(err, 'response.data'), function (value) {
                err.response.data.errors.push({'error': value});
            });
        } else {
            err.response.data.errors = [{'error': 'An unknown error occurred.'}];
        }

        throw err;
    }
};

/**
 * Generic action to perform a HTTP POST request.
 *
 * @param {Function} dispatch     Redux's dispatch function
 * @param {String} type           Action type to be dispatched (e.g. CHANGE_AUTH)
 * @param {String} endpoint       The endpoint to hit (e.g., '/auth/token')
 * @param {Object} data           The data to be posted with the request
 * @param {Boolean} requiresAuth  Whether or not request needs to be authenticated
 *
 * @returns {Promise}
 */
export const post = (dispatch, type, endpoint, data, requiresAuth) =>
    httpRequest(dispatch, POST, type, {endpoint, data, requiresAuth});

/**
 * Generic action to perform a HTTP PUT request.
 *
 * @param {Function} dispatch     Redux's dispatch function
 * @param {String} type           Action type to be dispatched (e.g. CHANGE_AUTH)
 * @param {String} endpoint       The endpoint to hit (e.g., '/auth/token')
 * @param {Object} data           The data to be posted with the request
 * @param {Boolean} requiresAuth  Whether or not request needs to be authenticated
 *
 * @returns {Promise}
 */
export const put = async(dispatch, type, endpoint, data, requiresAuth) =>
    httpRequest(dispatch, PUT, type, {endpoint, data, requiresAuth});

/**
 * Generic action to perform a HTTP PATCH request.
 *
 * @param {Function} dispatch     Redux's dispatch function
 * @param {String} type           Action type to be dispatched (e.g. CHANGE_AUTH)
 * @param {String} endpoint       The endpoint to hit (e.g., '/auth/token')
 * @param {Object} data           The data to be posted with the request
 * @param {Boolean} requiresAuth  Whether or not request needs to be authenticated
 *
 * @returns {Promise}
 */
export const patch = async(dispatch, type, endpoint, data, requiresAuth) =>
    httpRequest(dispatch, PATCH, type, {endpoint, data, requiresAuth});

/**
 * Generic action to perform a HTTP GET request.
 *
 * @param {Function} dispatch     Redux's dispatch function
 * @param {String} type           Action type to be dispatched (e.g. CHANGE_AUTH)
 * @param {String} endpoint       The endpoint to hit (e.g., '/auth/token')
 * @param {Boolean} requiresAuth  Whether or not request needs to be authenticated
 *
 * @returns {Promise}
 */
export const get = async(dispatch, type, endpoint, requiresAuth) =>
    httpRequest(dispatch, GET, type, {endpoint, requiresAuth});

/**
 * Generic action to perform a HTTP DELETE request.
 *
 * @param {Function} dispatch     Redux's dispatch function
 * @param {String} type           Action type to be dispatched (e.g. CHANGE_AUTH)
 * @param {String} endpoint       The endpoint to hit (e.g., '/auth/token')
 * @param {Boolean} requiresAuth  Whether or not request needs to be authenticated
 *
 * @returns {Promise}
 */
export const del = async(dispatch, type, endpoint, requiresAuth) =>
    httpRequest(dispatch, DELETE, type, {endpoint, requiresAuth});
