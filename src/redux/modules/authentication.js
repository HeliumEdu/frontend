import _ from "lodash";
import {APP_NAMESPACE} from "../../util/redux-constants";
import {get, post} from "../../util/http-utils";
import {deleteCookie, getCookie, setCookie} from "../../util/cookie-utils";
import {updateStore, buildGenericInitialState, handleError} from "../../util/store-utils";
import {getAppUrl} from "../../util/environment-utils";
import queryString from "query-string";

const AUTH_ENDPOINT_BASE = 'api/auth';
const typeBase = `${APP_NAMESPACE}/${AUTH_ENDPOINT_BASE}/`;

// Constants
export const CHANGE_AUTH = `${typeBase}CHANGE_AUTH`;
export const RESET_PASSWORD = `${typeBase}RESET_PASSWORD`;
export const GET_AUTHENTICATED_USER = `${typeBase}GET_AUTHENTICATED_USER`;


/**
 * login - Authenticate a user with an email and password
 * @param {Object} credentials  Login credentials (email, password)
 */
export const login = (credentials) => async(dispatch) => {
    try {
        console.log("Logging in ...");

        const response = await post(dispatch, CHANGE_AUTH, `${AUTH_ENDPOINT_BASE}/token/`, credentials, false);

        // If the login was successful, set the token as a cookie
        if (response) {
            console.log("Setting login cookie");

            setCookie('token', response.token, {maxAge: 1209600});

            const parsed = queryString.parse(window.location.search);
            if (!!parsed.length && 'next' in parsed) {
                window.location.href = `${getAppUrl()}${parsed['next']}`;
            } else {
                window.location.href = `${getAppUrl()}/dashboard/main`;
            }
        }
    } catch (err) {
        await handleError(dispatch, err, CHANGE_AUTH);
    }
};

/**
 * register - Creates a new account for a user
 * @param {Object} formData  User's form data
 */
export const register = formData => async(dispatch) => {
    try {
        const response = await post(dispatch, CHANGE_AUTH, `${AUTH_ENDPOINT_BASE}/register/`, formData, false);

        // If the registration was successful, set the JWT as a cookie
        if (response) {
            setCookie('token', response.token, {maxAge: 1209600});
            window.location.href = `${getAppUrl()}/dashboard/main`;
        }
    } catch (err) {
        await handleError(dispatch, err, CHANGE_AUTH);
    }
};

/**
 * logout  - Log user out by clearing auth state and token cookie
 */
export const logout = () => (dispatch) => {
    dispatch({type: CHANGE_AUTH, payload: {}});
    console.log("Deleting token");
    deleteCookie('token');

    window.location.href = `${getAppUrl()}/login`;
};

/**
 * forgotPassword - Sends user an email with a token to reset their password
 * @param {Object} formData  The user's email address
 * @returns {Promise}
 */
export const forgotPassword = formData => async(dispatch) => {
    try {
        const response = await post(dispatch, CHANGE_AUTH, `${AUTH_ENDPOINT_BASE}/forgot-password/`, formData, false);
        return Promise.resolve(response);
    } catch (err) {
        await handleError(dispatch, err, CHANGE_AUTH);
    }
};

/**
 * resetPassword - Resets a user's password, given a valid token
 * @param {Object} formData  The user's email address
 * @param {String} token     Valid token required for password reset
 * @returns {Promise}
 */
export const resetPassword = (formData, token) => async(dispatch) => {
    try {
        const response = await post(dispatch, CHANGE_AUTH, `${AUTH_ENDPOINT_BASE}/reset-password/${token}/`, formData, false);
        return Promise.resolve(response);
    } catch (err) {
        await handleError(dispatch, err, CHANGE_AUTH);
    }
};

/**
 * getAuthenticatedUser - Retrieves the logged in user's information
 * @returns {Promise}
 */
export const getAuthenticatedUser = () => async(dispatch) => {
    try {
        const response = await get(dispatch, GET_AUTHENTICATED_USER, `${AUTH_ENDPOINT_BASE}/user/`, true);
        return Promise.resolve(response);
    } catch (err) {
        await handleError(dispatch, err, GET_AUTHENTICATED_USER);
    }
};

// Store
const INITIAL_STATE = {
    token: getCookie('token'),
    user: '',
    ...buildGenericInitialState([CHANGE_AUTH, RESET_PASSWORD, GET_AUTHENTICATED_USER])
};

export default (state = INITIAL_STATE, action) => {
    switch (action.type) {
        case CHANGE_AUTH:
            return updateStore(state, action, {
                token: _.get(action, 'payload.token'),
                user: _.get(action, 'payload.user.id')
            });
        case GET_AUTHENTICATED_USER:
            return updateStore(state, action, {user: _.get(action, 'payload.user.id')});
        default:
            return state;
    }
};
