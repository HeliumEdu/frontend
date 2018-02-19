import React, {Component} from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import {reduxForm} from "redux-form";
import TextInput from "../components/form-fields/text-input";
import GenericForm from "../components/form-fields/generic-form";
import {login, CHANGE_AUTH} from "../redux/modules/authentication";
import {errorPropTypes} from "../util/proptype-utils";
import queryString from "query-string";
import "./authentication.css";

const form = reduxForm({
    form: 'login'
});

class Login extends Component {
    state = {
        redirecting: false
    };

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
        }
    ];

    componentWillMount = () => {
        const {token} = this.props;

        if (token) {
            const parsed = queryString.parse(window.location.search);
            if (!!parsed.length && 'next' in parsed) {
                this.props.history.push(parsed['next']);
            } else {
                this.props.history.push('/planner/calendar');
            }
        }
    };

    componentWillUpdate = (nextProps) => {
        this.state.redirecting = !!nextProps.token;

        return true;
    };

    handleFormSubmit = (formProps) => {
        this.props.login(formProps);
    };

    render = () => {
        const {handleSubmit, errors, message, loading} = this.props;
        const {redirecting} = this.state;

        return (
            <div className={`auth-box ${loading || redirecting ? 'is-loading' : ''}`}>
                <h1>Login</h1>
                <GenericForm
                    onSubmit={handleSubmit(this.handleFormSubmit)}
                    errors={errors}
                    message={message}
                    formSpec={Login.formSpec}
                    submitText="Login"
                />
            </div>
        );
    }
}

const mapStateToProps = ({authentication}) => ({
    errors: authentication.errors[CHANGE_AUTH],
    message: authentication.messages[CHANGE_AUTH],
    loading: authentication.loading[CHANGE_AUTH],
    token: authentication.token
});
export default connect(mapStateToProps, {login})(form(Login));
