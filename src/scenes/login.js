import React, {Component} from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import {reduxForm} from "redux-form";
import {Link} from "react-router-dom";
import TextInput from "../components/form-fields/text-input";
import GenericForm from "../components/form-fields/generic-form";
import {login, CHANGE_AUTH} from "../redux/modules/authentication";
import {errorPropTypes} from "../util/proptype-utils";
import _ from "lodash";
import queryString from "query-string";
import "./authentication.css";

const form = reduxForm({
    form: 'login',
});

class Login extends Component {
    static propTypes = {
        handleSubmit: PropTypes.func,
        login: PropTypes.func,
        errors: errorPropTypes,
        message: PropTypes.string,
        loading: PropTypes.bool
    };

    static formSpec = [
        {
            id: 'username',
            name: 'username',
            label: 'Username',
            type: 'text',
            placeholder: 'Username',
            component: TextInput
        },
        {
            id: 'password',
            name: 'password',
            label: 'Password',
            type: 'password',
            placeholder: 'Password',
            component: TextInput
        },
    ];

    handleFormSubmit = (formProps) => {
        this.props.login(formProps);
    }

    render = () => {
        const {handleSubmit, errors, message, loading} = this.props;

        if (this.props.authenticated) {
            const parsed = queryString.parse(window.location.search);
            if (!_.isEmpty(parsed) && 'next' in parsed) {
                this.props.history.push(parsed['next']);
            } else {
                this.props.history.push('/dashboard/main');
            }

            return null;
        } else {
            return (
                <div className={`auth-box ${loading ? 'is-loading' : ''}`}>
                    <h1>Login</h1>
                    <GenericForm
                        onSubmit={handleSubmit(this.handleFormSubmit)}
                        errors={errors}
                        message={message}
                        formSpec={Login.formSpec}
                        submitText="Login"
                    />
                    <Link className="inline" to="/forgot-password">Forgot password?</Link> | <Link className="inline"
                                                                                                   to="/register">Create
                    a
                    new account.</Link>
                </div>
            );
        }
    }
}

const mapStateToProps = ({authentication}) => ({
    errors: authentication.errors[CHANGE_AUTH],
    message: authentication.messages[CHANGE_AUTH],
    loading: authentication.loading[CHANGE_AUTH],
    authenticated: authentication.authenticated,
});

export default connect(mapStateToProps, {login})(form(Login));
