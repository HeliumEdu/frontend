import React from "react";
import {fieldPropTypes} from "../../util/proptype-utils";

const IconTextInput = ({input, id, placeholder, type, icon, extraClasses = '', autoFocus = false}) => (
    <label htmlFor={id} className="block clearfix">
        <div className="input-group no-padding">
            <span className="input-group-addon">
                <i className={icon}/>
            </span>

            <input
                {...input}
                id={id}
                className={`form-control ${extraClasses}`}
                placeholder={placeholder}
                type={type}
                autoFocus={autoFocus}
            />
        </div>
    </label>
);

IconTextInput.propTypes = fieldPropTypes;

export default IconTextInput;