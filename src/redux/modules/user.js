import _ from "lodash";
import {updateStore, buildGenericInitialState} from "../../util/store-utils";
import {put} from "../../util/http-utils";
import {CHANGE_AUTH, GET_AUTHENTICATED_USER} from "./authentication";
import {APP_NAMESPACE} from "../../util/redux-constants";

const USER_ENDPOINT_BASE = 'auth/user';
const typeBase = `${APP_NAMESPACE}/${USER_ENDPOINT_BASE}`;

// Constants
export const VERIFY_USER = `${typeBase}/VERIFY_USER`;

// Actions
export const verify = (queryString) => async(dispatch) => {
    // TODO: ensure "username" and "code" are present in query parameters

    try {
        // TODO: append username and code as query string
        const response = await put(dispatch, VERIFY_USER, `${USER_ENDPOINT_BASE}/verify/`, {}, false);

        // TODO: on success, redirect to "login" page with status about the email being verified and ready to login

        window.location.replace(`${process.env.REACT_APP_HOST}/login`);
    } catch (err) {
        // TODO: redirect to /login page and show error message
        window.location.replace(`${process.env.REACT_APP_HOST}/login`);
    }
};

// Store
const INITIAL_STATE = {
    ...buildGenericInitialState([])
};

export default function user(state = INITIAL_STATE, action) {
    switch (action.type) {
        case CHANGE_AUTH:
            return updateStore(state, action, _.get(action, 'payload.user.id') ? {[action.payload.user.id]: action.payload.user} : {});
        case GET_AUTHENTICATED_USER:
            return updateStore(state, action, _.get(action, 'payload.user.id') ? {[action.payload.user.id]: action.payload.user} : {});
        default:
            return state;
    }
};

// Selectors
export const getAuthenticatedUser = ({user, authentication}) => user[authentication.user];
