import React, {Component} from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import {reduxForm} from "redux-form";
import GenericForm from "../../components/form-fields/generic-form";
import IconTextInput from "../../components/form-fields/icon-text-input";
import Checkbox from "../../components/form-fields/checkbox";
import ChosenSelect from "../../components/form-fields/chosen-select";
import {register, REGISTER_USER} from "../../redux/modules/authentication";
import {messagePropTypes, errorPropTypes} from "../../util/proptype-utils";
import {TIME_ZONE_CHILDREN} from "../../util/ui-constants";

const form = reduxForm({
    form: 'register'
});

class Register extends Component {
    static propTypes = {
        handleSubmit: PropTypes.func,
        login: PropTypes.func,
        errors: errorPropTypes,
        messages: messagePropTypes
    };

    static formSpec = [
        {
            id: 'username',
            name: 'username',
            type: 'text',
            icon: 'icon-user',
            placeholder: 'Username',
            autoFocus: true,
            required: true,
            component: IconTextInput
        },
        {
            id: 'email',
            name: 'email',
            type: 'email',
            icon: 'icon-envelope',
            placeholder: 'Email',
            required: true,
            component: IconTextInput
        },
        {
            id: 'password1',
            name: 'password1',
            type: 'password',
            icon: 'icon-lock',
            placeholder: 'Password',
            required: true,
            component: IconTextInput
        },
        {
            id: 'password2',
            name: 'password2',
            type: 'password',
            icon: 'icon-retweet',
            placeholder: 'Confirm password',
            required: true,
            component: IconTextInput
        },
        {
            id: 'time_zone',
            name: 'time_zone',
            label: 'Time zone',
            children: TIME_ZONE_CHILDREN,
            component: ChosenSelect
        },
        {
            id: 'policy_agreement',
            name: 'policy_agreement',
            required: true,
            label: <span>I agree to Helium's <a href='/terms' target='_blank'>Terms of Service</a> and <a href='/privacy' target='_blank'>Privacy Policy</a></span>,
            component: Checkbox
        }
    ];

    handleFormSubmit = (formProps) => {
        this.props.register(this.props.history, formProps);
    };

    render = () => {
        const {handleSubmit, errors, messages} = this.props;

        return (
            <div className="main-container">
                <div className="container">
                    <div className="page-content">
                        <div className="row">
                            <div className="col-sm-10 col-sm-offset-1">
                                <div className="login-container">
                                    <div className="well">
                                        <h4 className="header green lighter bigger">
                                            <i className="icon-user blue"/>&nbsp;
                                            New User Registration
                                        </h4>

                                        <div className="space-6"></div>

                                        <GenericForm
                                            onSubmit={handleSubmit(this.handleFormSubmit)}
                                            errors={errors}
                                            messages={messages}
                                            formSpec={Register.formSpec}
                                            submitText="Sign Me Up!"
                                            submitIcon="icon-signin"
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
}

const mapStateToProps = ({authentication}) => ({
    errors: authentication.errors[REGISTER_USER],
    messages: authentication.messages[REGISTER_USER]
});

export default connect(mapStateToProps, {register})(form(Register));