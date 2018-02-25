import React from "react";
import {messagePropTypes, errorPropTypes} from "../../util/proptype-utils";

const Alert = ({errors = [], messages = []}) => {
    const alertType = errors && errors.length ? 'warning' : 'info';
    const shouldShow = Boolean((errors && errors.length) || (messages && messages.length));

    return (
        <div className={`alert alert-${alertType} ${shouldShow ? '' : 'hidden'}`}>
            {(errors && errors.length) ? errors.map((error, index) => <span key={index}>{error.error}&nbsp;</span>) : ""}
            {(messages && messages.length) ? messages.map((message, index) => <span key={index}>{message.message}&nbsp;</span>) : ""}
        </div>
    );
};

Alert.propTypes = {
    errors: errorPropTypes,
    messages: messagePropTypes
};

export default Alert;
