import _ from "lodash";
import {PENDING, SUCCESS, ERROR} from "./redux-constants";

/**
 * Update the Redux store and return the new state. This helper also first builds generic state if
 * necessary (messages, errors, loading).
 */
export const updateStore = (state, action, extraValues = {}) => {
    const {type = '', payload = {}, meta = {status: ''}} = action;
    switch (meta.status) {
        case SUCCESS:
            return {
                ...state,
                ...extraValues,
                messages: {...state.messages, [type]: _.get(payload, 'message')},
                loading: {...state.loading, [type]: false},
                errors: {...state.errors, [type]: []}
            };
        case ERROR:
            return {
                ...state,
                messages: {...state.messages, [type]: ''},
                loading: {...state.loading, [type]: false},
                errors: {
                    ...state.errors,
                    [type]: _.get(payload, 'data.errors') || _.get(payload, 'errors') || action.payload || []
                }
            };
        case PENDING:
        default:
            return {
                ...state,
                messages: {...state.messages, [type]: ''},
                loading: {...state.loading, [type]: true},
                errors: {...state.errors, [type]: []}
            };
    }
};

/**
 * Build an initial state for a set of constants (loading, errors, messages)
 */
export const buildGenericInitialState = (constants) => ({
    messages: constants.reduce((retObj, constant) => {
        retObj[constant] = '';
        return retObj;
    }, {}),
    errors: constants.reduce((retObj, constant) => {
        retObj[constant] = [];
        return retObj;
    }, {}),
    loading: constants.reduce((retObj, constant) => {
        retObj[constant] = false;
        return retObj;
    }, {})
});

/**
 * Dispatch errors to Redux stores
 */
export const handleError = (dispatch, error, type) => {
    const foundError = _.get(error, 'response.data.errors') || [{error}];
    return dispatch({
        type,
        payload: foundError,
        meta: {status: ERROR}
    });
};
