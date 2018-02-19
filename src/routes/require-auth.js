import React, {Component} from "react";
import PropTypes from "prop-types";
import _ from "lodash";
import {connect} from "react-redux";
import {withRouter} from "react-router-dom";
import {getAuthenticatedUser} from "../redux/modules/authentication";

export default (ComposedComponent) => {
    class Authentication extends Component {
        static propTypes = {
            token: PropTypes.string,
            history: PropTypes.shape({
                push: PropTypes.func
            }),
            getAuthenticatedUser: PropTypes.func
        };

        static unauthenticatedRoutes = ['/', '/register', '/verify', '/login', '/logout', '/forgot', '/support', '/terms', '/privacy', '/press', '/about', '/contact'];

        componentDidMount = () => this.ensureAuthentication(!!this.props.token);

        componentWillUpdate = (nextProps) => {
            if (this.props.token !== nextProps.token) {
                this.ensureAuthentication(nextProps.token);
            }
        };

        ensureAuthentication = (isAuthenticated) => {
            if (!isAuthenticated) {
                const path = _.get(this.props.location, 'pathname');

                // Save the user's path for future redirect
                if (path && !Authentication.unauthenticatedRoutes.includes(path)) {
                    return this.props.history.push(`/login?next=${path}`);
                } else {
                    return this.props.history.push('/login');
                }
            }

            return this.props.getAuthenticatedUser();
        };

        render() {
            return <ComposedComponent {...this.props} />;
        }
    }

    const mapStateToProps = ({authentication}) => ({token: authentication.token});

    return withRouter(connect(mapStateToProps, {getAuthenticatedUser})(Authentication));
};
