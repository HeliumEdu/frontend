import React from "react";
import PropTypes from "prop-types";
import {errorPropTypes} from "../../util/proptype-utils";

const Alert = ({errors = [], message = ''}) => {
    const alertType = errors && errors.length ? 'warning' : 'info';
    const shouldShow = Boolean((errors && errors.length) || message);

    return (
        <div className={`alert alert-${alertType} ${shouldShow ? '' : 'hidden'}`}>
            {(errors && errors.length) &&
            errors.map((error, index) => <span key={index}>{error.error}&nbsp;</span>)
            }
            {message && <span>{message}</span>}
        </div>
    );
};

Alert.propTypes = {
    errors: errorPropTypes,
    message: PropTypes.string
};

export default Alert;
