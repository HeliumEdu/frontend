import React from "react";
import PropTypes from "prop-types";
import {Field} from "redux-form";
import Alert from "../notification/alert";
import {errorPropTypes} from "../../util/proptype-utils";

const LoginForm = ({errors = [], message = '', onSubmit}) => (
    <form className="form" onSubmit={onSubmit}>
        <Alert errors={errors}/>
        <Alert message={message}/>

        <fieldset>
            <label className="block clearfix">
                <div className="input-group no-padding">
                    <span className="input-group-addon">
                        <i className="icon-user"/>
                    </span>

                    <Field className="form-control" component="input" type="text" id="username" name="username"
                           placeholder="Username" required autoFocus/>
                </div>
            </label>

            <label className="block clearfix">
                <div className="input-group no-padding">
                    <span className="input-group-addon">
                        <i className="icon-lock"/>
                    </span>

                    <Field className="form-control" component="input" type="password" id="password" name="password"
                           placeholder="Password" required />
                </div>
            </label>

            <div className="space"></div>

            <button type="submit" className="width-35 pull-right btn btn-sm btn-primary">
                Sign in
                &nbsp;<i className="icon-signin icon-on-right"/>
            </button>
            <br />
        </fieldset>
    </form>
);

LoginForm.propTypes = {
    onSubmit: PropTypes.func,
    message: PropTypes.string,
    errors: errorPropTypes
};

export default LoginForm;
