import _ from 'lodash';
import { APP_NAMESPACE } from '../../util/redux-constants';
import { put, post, get, del } from '../../util/http-utils';
import { updateStore, buildGenericInitialState, handleError } from '../../util/store-utils';
import { CHANGE_AUTH, GET_AUTHENTICATED_USER } from './authentication';

const USER_ENDPOINT_BASE = 'api/auth/user';
const typeBase = `${APP_NAMESPACE}/${USER_ENDPOINT_BASE}/`;

// Constants
export const GET_USER = `${typeBase}GET_USER`;
export const GET_USERS = `${typeBase}GET_USERS`;

// Actions

/**
 * getUser  - Fetches user from API, given id
 *
 * @param {String} id User's id for lookup
 * @returns {Promise}
 */
export const getUser = id => async (dispatch) => {
  try {
    const response = await get(dispatch, GET_USER, `${USER_ENDPOINT_BASE}/${id}/`, true);
    return Promise.resolve(response);
  } catch (err) {
    await handleError(dispatch, err, GET_USER);
  }
};

// Store
const INITIAL_STATE = {
  ...buildGenericInitialState([GET_USER]),
};

export default (state = INITIAL_STATE, action) => {
  switch (action.type) {
    case CHANGE_AUTH:
      return updateStore(state, action, _.get(action, 'payload.user.id') ? { [action.payload.user.id]: action.payload.user } : {});
    case GET_USER:
    case GET_AUTHENTICATED_USER:
      return updateStore(state, action, _.get(action, 'payload.user.id') ? { [action.payload.user.id]: action.payload.user } : {});
    default:
      return state;
  }
};

// Selectors
export const getAuthenticatedUser = ({ user, authentication }) => user[authentication.user];
