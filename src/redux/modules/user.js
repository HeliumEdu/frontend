import _ from "lodash";
import {updateStore, buildGenericInitialState, handleError, handleMessage} from "../../util/store-utils";
import {get} from "../../util/http-utils";
import {CHANGE_AUTH, GET_AUTHENTICATED_USER} from "./authentication";
import {APP_NAMESPACE} from "../../util/redux-constants";
import queryString from "query-string";

const USER_ENDPOINT_BASE = 'auth/user';
const typeBase = `${APP_NAMESPACE}/${USER_ENDPOINT_BASE}`;

// Constants
export const VERIFY_USER = `${typeBase}/VERIFY_USER`;

// Actions
export const verify = (history) => async(dispatch) => {
    try {
        const parsed = queryString.parse(window.location.search);

        await get(dispatch, VERIFY_USER, `${USER_ENDPOINT_BASE}/verify/?username=${parsed.username}&code=${parsed.code}`, false);

        await handleMessage(dispatch,
            "Your email address has been verified. You can now login to Helium using this email or your username.",
            VERIFY_USER);

        history.replace('/login');
    } catch (err) {
        await handleError(dispatch, err, CHANGE_AUTH);

        history.replace('/login');
    }
};

// Store
const INITIAL_STATE = {
    ...buildGenericInitialState([VERIFY_USER])
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
