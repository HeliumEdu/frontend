import React from "react";
import PropTypes from "prop-types";
import {fieldPropTypes} from "../../util/proptype-utils";
import $ from "jquery";

window.jQuery = $;
require("chosen-js");


class ChosenSelect extends React.Component {
    componentDidMount() {
        $(this.refs.select).chosen();
    }

    render = () => {
        const {input, label, children, extraClasses} = this.props;

        return (
            <div className="block clearfix">
                <label className="col-sm-4 control-label" htmlFor={input.id}>{label}</label>

                <div className="col-sm-8">
                    <select
                        ref="select"
                        {...input}
                        className={`form-control chosen-select ${extraClasses && extraClasses}`}
                    >
                        {children}
                    </select>
                </div>
            </div>
        );
    }
}

ChosenSelect.defaultProps = {
    label: '',
    extraClasses: ''
};

ChosenSelect.propTypes = {
    ...fieldPropTypes,
    children: PropTypes.node
};

export default ChosenSelect;