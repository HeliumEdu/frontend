import React, {Component} from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import {reduxForm} from "redux-form";
import GenericForm from "../../components/form-fields/generic-form";
import TextInput from "../../components/form-fields/text-input";
import {Link} from "react-router-dom";
import {forgot, RESET_PASSWORD} from "../../redux/modules/authentication";
import {errorPropTypes} from "../../util/proptype-utils";

const form = reduxForm({
    form: 'forgot'
});

class Forgot extends Component {
    static propTypes = {
        handleSubmit: PropTypes.func,
        login: PropTypes.func,
        errors: errorPropTypes,
        message: PropTypes.string
    };

    static formSpec = [
        {
            id: 'email',
            name: 'email',
            type: 'email',
            icon: 'icon-envelope',
            placeholder: 'Email',
            autoFocus: true,
            component: TextInput
        }
    ];

    handleFormSubmit = (formProps) => {
        this.props.forgot(this.props.history, formProps);
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
                                        <h4 className="header blue lighter bigger">
                                            <i className="icon-key blue"/>&nbsp;
                                            Retrieve Password
                                        </h4>

                                        Enter the email associated with your account. We'll reset your password and send
                                        the temporary password to your email address.

                                        <div className="space-6"></div>

                                        <GenericForm
                                            onSubmit={handleSubmit(this.handleFormSubmit)}
                                            errors={errors}
                                            message={message}
                                            formSpec={Forgot.formSpec}
                                            submitText="Get It"
                                            submitIcon="icon-lock"
                                        />

                                        <div className="clearfix">
                                            <Link to="/register">
                                                Need an account?
                                            </Link>
                                        </div>
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
    errors: authentication.errors[RESET_PASSWORD],
    message: authentication.messages[RESET_PASSWORD]
});

export default connect(mapStateToProps, {forgot})(form(Forgot));