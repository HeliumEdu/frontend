import React, {Component} from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import {reduxForm} from "redux-form";
import GenericForm from "../../components/form-fields/generic-form";
import TextInput from "../../components/form-fields/text-input";
import {register, REGISTER_USER} from "../../redux/modules/authentication";
import {errorPropTypes} from "../../util/proptype-utils";

const form = reduxForm({
    form: 'register'
});

class Register extends Component {
    static propTypes = {
        handleSubmit: PropTypes.func,
        login: PropTypes.func,
        errors: errorPropTypes,
        message: PropTypes.string
    };

    static formSpec = [
        {
            id: 'username',
            name: 'username',
            type: 'text',
            icon: 'icon-user',
            placeholder: 'Username',
            autoFocus: true,
            component: TextInput
        },
        {
            id: 'email',
            name: 'email',
            type: 'email',
            icon: 'icon-envelope',
            placeholder: 'Email',
            component: TextInput
        },
        {
            id: 'password1',
            name: 'password1',
            type: 'password',
            icon: 'icon-lock',
            placeholder: 'Password',
            component: TextInput
        },
        {
            id: 'password2',
            name: 'password2',
            type: 'password',
            icon: 'icon-retweet',
            placeholder: 'Confirm password',
            component: TextInput
        }
        // TODO: time_zone
        // TODO: agree to policy and tos
    ];

    handleFormSubmit = (formProps) => {
        this.props.register(this.props.history, formProps);
    };

    render = () => {
        const {handleSubmit, errors, message} = this.props;

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
                                            message={message}
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
    message: authentication.messages[REGISTER_USER]
});

export default connect(mapStateToProps, {register})(form(Register));