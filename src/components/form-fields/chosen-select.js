import React from "react";
import PropTypes from "prop-types";
import {fieldPropTypes} from "../../util/proptype-utils";
// import "chosen-js/chosen.css";
import $ from "jquery";

window.jQuery = $;
// require("chosen-js");


class ChosenSelect extends React.Component {
    componentDidMount() {
        const {input} = this.props;

        this.handleChange = this.handleChange.bind(this);

        this.$el = $(this.el);
        this.$el.chosen({width: "100%", search_contains: true});
        this.$el.on('change', this.handleChange);
        this.$el.val(input.value);
    }

    componentDidUpdate(prevProps) {
        if (prevProps.children !== this.props.children) {
            this.$el.trigger("chosen:updated");
        }
    }

    componentWillUnmount() {
        this.$el.off('change', this.handleChange);
        this.$el.chosen('destroy');
    }

    handleChange(e) {
        // this.props.onChange(e.target.value);
    }

    render = () => {
        const {input, label, children, extraClasses} = this.props;

        return (
            <div className="block clearfix">
                <label className="col-sm-4 control-label" htmlFor={input.id}>{label}</label>

                <div className="col-sm-8">
                    <select
                        ref={el => this.el = el}
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