import React from "react";
import PropTypes from "prop-types";
import {Field} from "redux-form";
import Alert from "../notification/alert";
import {errorPropTypes} from "../../util/proptype-utils";

const GenericForm = ({formSpec = [], errors = [], message = '', onSubmit, submitText}) => (
    <form className="form" onSubmit={onSubmit}>
        <Alert errors={errors}/>
        <Alert message={message}/>

        <fieldset>
            <ul className="form-list">
                {formSpec.map(field => <li key={field.id}><Field {...field} /></li>)}
            </ul>
            <button type="submit" className="width-35 pull-right btn btn-sm btn-primary">{submitText}</button>
            <br />
        </fieldset>
    </form>
);

GenericForm.propTypes = {
    onSubmit: PropTypes.func,
    formSpec: PropTypes.arrayOf(PropTypes.shape({
        placeholder: PropTypes.string,
        type: PropTypes.string,
        id: PropTypes.string,
        name: PropTypes.string,
        label: PropTypes.string,
        component: PropTypes.func
    })),
    message: PropTypes.string,
    errors: errorPropTypes,
    submitText: PropTypes.string
};

export default GenericForm;
