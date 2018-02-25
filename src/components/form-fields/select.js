import React from "react";
import PropTypes from "prop-types";
import {fieldPropTypes} from "../../util/proptype-utils";

const Select = ({input, children, label = '', extraClasses = ''}) => (
    <div className="block clearfix">
        <label className="col-sm-4 control-label" htmlFor={input.id}>{label}</label>

        <div className="col-sm-8">
            <select
                {...input}
                className={`form-control chosen-select ${extraClasses && extraClasses}`}
            >
                {children}
            </select>
        </div>
    </div>
);

Select.propTypes = {
    ...fieldPropTypes,
    children: PropTypes.node
};

export default Select;
