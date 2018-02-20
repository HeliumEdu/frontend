import _ from "lodash";
// import {APP_NAMESPACE} from "../../util/redux-constants";
import {updateStore, buildGenericInitialState} from "../../util/store-utils";
import {CHANGE_AUTH, GET_AUTHENTICATED_USER} from "./authentication";

// const USER_ENDPOINT_BASE = 'api/auth/user';
// const typeBase = `${APP_NAMESPACE}/${USER_ENDPOINT_BASE}`;

// Constants


// Actions


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
