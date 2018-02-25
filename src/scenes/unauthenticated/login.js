import React, {Component} from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import {reduxForm} from "redux-form";
import GenericForm from "../../components/form-fields/generic-form";
import IconTextInput from "../../components/form-fields/icon-text-input";
import {Link} from "react-router-dom";
import {login, CHANGE_AUTH} from "../../redux/modules/authentication";
import {messagePropTypes, errorPropTypes} from "../../util/proptype-utils";
import queryString from "query-string";

const form = reduxForm({
    form: 'login'
});

class Login extends Component {
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
            id: 'password',
            name: 'password',
            type: 'password',
            icon: 'icon-lock',
            placeholder: 'Password',
            required: true,
            component: IconTextInput
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

    handleFormSubmit = (formProps) => {
        this.props.login(this.props.history, formProps);
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
                                        <h4 className="header blue lighter bigger">
                                            <i className="icon-key blue"/>&nbsp;
                                            Enter Your Login Information
                                        </h4>

                                        <div className="space-6"></div>

                                        <GenericForm
                                            onSubmit={handleSubmit(this.handleFormSubmit)}
                                            errors={errors}
                                            messages={messages}
                                            formSpec={Login.formSpec}
                                            submitText="Sign In"
                                            submitIcon="icon-signin"
                                        />

                                        <div className="clearfix">
                                            <Link to="/register">
                                                Need an account?
                                            </Link>
                                            <Link to="/forgot" className="pull-right">
                                                Forgot your password?
                                            </Link>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        );
    }
}

const mapStateToProps = ({authentication}) => ({
    errors: authentication.errors[CHANGE_AUTH],
    messages: authentication.messages[CHANGE_AUTH],
    token: authentication.token
});

export default connect(mapStateToProps, {login})(form(Login));
