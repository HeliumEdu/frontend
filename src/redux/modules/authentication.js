import _ from "lodash";
import {APP_NAMESPACE} from "../../util/redux-constants";
import {get, post, put} from "../../util/http-utils";
import {deleteCookie, getCookie, setCookie} from "../../util/cookie-utils";
import {updateStore, buildGenericInitialState, handleMessage, handleError} from "../../util/store-utils";
import queryString from "query-string";

const AUTH_ENDPOINT_BASE = 'auth';
const typeBase = `${APP_NAMESPACE}/${AUTH_ENDPOINT_BASE}`;

// Constants
export const REGISTER_USER = `${typeBase}/REGISTER_USER`;
export const CHANGE_AUTH = `${typeBase}/CHANGE_AUTH`;
export const GET_AUTHENTICATED_USER = `${typeBase}/GET_AUTHENTICATED_USER`;
export const RESET_PASSWORD = `${typeBase}/RESET_PASSWORD`;

// Actions
export const register = (history, formData) => async(dispatch) => {
    // TODO: ensure password1 matches password2, if not error, if so rename password1 to just password and pop password2

    // TODO: ensure TOS checkbox is checked, error if not

    try {
        const response = await put(dispatch, REGISTER_USER, `${AUTH_ENDPOINT_BASE}/user/register/`, formData, false);

        // TODO: on success, redirect to "login" page with status "You're almost there! The last step is to verify your email address. Click the link in the email we just sent you and your registration will be complete!"

        history.push('/login');
    } catch (err) {
        await handleError(dispatch, err, REGISTER_USER);
    }
};

export const login = (history, formData) => async(dispatch) => {
    try {
        const response = await post(dispatch, CHANGE_AUTH, `${AUTH_ENDPOINT_BASE}/token/`, formData, false);

        // If the login was successful, set the token as a cookie
        if (response) {
            setCookie('token', response.token, {maxAge: 1209600});

            const parsed = queryString.parse(window.location.search);
            if (!!parsed.length && 'next' in parsed) {
                history.push(parsed['next']);
            } else {
                history.push('/planner/calendar');
            }
        }
    } catch (err) {
        await handleError(dispatch, err, CHANGE_AUTH);
    }
};

export const forgot = (history, formData) => async(dispatch) => {
    try {
        const response = await put(dispatch, RESET_PASSWORD, `${AUTH_ENDPOINT_BASE}/user/forgot/`, formData, false);

        await handleMessage(dispatch, "You've been emailed a temporary password. Login to your account immediately using the temporary password, then change your password.", RESET_PASSWORD);
    } catch (err) {
        await handleError(dispatch, err, RESET_PASSWORD);
    }
};

export const logout = () => async(dispatch) => {
    await dispatch({type: CHANGE_AUTH, payload: {}});
    deleteCookie('token');

    window.location.replace(`${process.env.REACT_APP_HOST}/login`);
};

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

export default function authentication(state = INITIAL_STATE, action) {
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
