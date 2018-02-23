import React from "react";
import PropTypes from "prop-types";
import {Field} from "redux-form";
import Alert from "../notification/alert";
import {errorPropTypes} from "../../util/proptype-utils";

const GenericForm = ({formSpec = [], errors = [], message = '', submitIcon = '', submitText, onSubmit}) => (
    <form className="form" onSubmit={onSubmit}>
        <Alert errors={errors}/>
        <Alert message={message}/>

        <fieldset>
            {formSpec.map(field => <Field key={field.id} {...field} />)}

            <div className="space"></div>

            <button type="submit" className="width-35 pull-right btn btn-sm btn-primary">
                {submitText}
                &nbsp;<i className={`icon-on-right ${submitIcon}`}/>
            </button>
            <br />
        </fieldset>
    </form>
);

GenericForm.propTypes = {
    onSubmit: PropTypes.func,
    message: PropTypes.string,
    errors: errorPropTypes,
    formSpec: PropTypes.arrayOf(PropTypes.shape({
        placeholder: PropTypes.string,
        type: PropTypes.string,
        id: PropTypes.string,
        name: PropTypes.string,
        label: PropTypes.string,
        component: PropTypes.func,
        autoFocus: PropTypes.bool
    })),
    submitText: PropTypes.string,
    submitIcon: PropTypes.string
};

export default GenericForm;
