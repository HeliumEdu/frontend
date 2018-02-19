import React, {Component} from "react";
import PropTypes from "prop-types";
import _ from "lodash";
import {connect} from "react-redux";
import {withRouter} from "react-router-dom";
import {getAuthenticatedUser} from "../redux/modules/authentication";

export default (ComposedComponent) => {
    class Authentication extends Component {
        static propTypes = {
            authenticated: PropTypes.bool,
            history: PropTypes.shape({
                push: PropTypes.func,
            }),
            getAuthenticatedUser: PropTypes.func,
        };

        // List of pre-authention routes, so they aren't saved for a post-auth redirect
        static preAuthRoutes = ['/login', '/register', '/forgot-password'];

        componentDidMount = () => this.ensureAuthentication(this.props.authenticated);

        componentWillUpdate = (nextProps) => {
            if (this.props.authenticated !== nextProps.authenticated) {
                this.ensureAuthentication(nextProps.authenticated);
            }
        };

        ensureAuthentication = (isAuthed) => {
            if (!isAuthed) {
                const path = _.get(this.props.location, 'pathname');

                // Save the user's path for future redirect
                if (path && !Authentication.preAuthRoutes.includes(path)) {
                    return this.props.history.push(`/login?next=${path}`);
                } else {
                    return this.props.history.push('/login');
                }
            }

            return this.props.getAuthenticatedUser();
        }

        render() {
            return <ComposedComponent {...this.props} />;
        }
    }

    const mapStateToProps = ({authentication}) => ({authenticated: authentication.authenticated});

    return withRouter(connect(mapStateToProps, {getAuthenticatedUser})(Authentication));
};
