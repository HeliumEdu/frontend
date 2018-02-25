import React from "react";
import {fieldPropTypes} from "../../util/proptype-utils";

const IconTextInput = ({input, placeholder, type, icon, extraClasses = '', required = false, autoFocus = false}) => (
    <label htmlFor={input.id} className="block clearfix">
        <div className="input-group no-padding">
            <span className="input-group-addon">
                <i className={icon}/>
            </span>

            <input
                {...input}
                className={`form-control ${extraClasses}`}
                placeholder={placeholder}
                type={type}
                required={required}
                autoFocus={autoFocus}
            />
        </div>
    </label>
);

IconTextInput.propTypes = fieldPropTypes;

export default IconTextInput;