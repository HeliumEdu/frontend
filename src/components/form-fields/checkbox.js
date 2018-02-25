import React from "react";
import {fieldPropTypes} from "../../util/proptype-utils";

const Checkbox = ({input, required=false, label = '', extraClasses = ''}) => (
    <label className="block">
        <input {...input} type="checkbox" className={`ace ${extraClasses && extraClasses}`}
                          required={required}/>
        <span className="lbl">&nbsp;{label}</span>
    </label>
);

Checkbox.propTypes = fieldPropTypes;

export default Checkbox;
