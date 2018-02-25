import PropTypes from "prop-types";

export const messagePropTypes = PropTypes.arrayOf(PropTypes.shape({
    message: PropTypes.string
}));

export const errorPropTypes = PropTypes.arrayOf(PropTypes.shape({
    error: PropTypes.string
}));

export const fieldPropTypes = {
    input: PropTypes.shape({
        id: PropTypes.string,
        name: PropTypes.string,
        value: PropTypes.oneOfType([
            PropTypes.string,
            PropTypes.bool
        ])
    }),
    placeholder: PropTypes.string,
    type: PropTypes.string,
    extraClasses: PropTypes.string,
    label: PropTypes.oneOfType([
        PropTypes.string,
        PropTypes.object
    ]),
    required: PropTypes.bool,
    autoFocus: PropTypes.bool
};
