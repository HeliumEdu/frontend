import React, {Component} from "react";
import PropTypes from "prop-types";
import ReminderMenu from "../notification/reminder-menu";
import {connect} from "react-redux";
import {withRouter, Link} from "react-router-dom";
import {getAuthenticatedUser} from "../../redux/modules/user";

class Header extends Component {
    buildHeaderNavigation = () => {
        const {pathname} = this.props.location;
        const isAuthenticated = !!this.props.token;

        return (
            <div className="collapse navbar-collapse">
                { isAuthenticated ?
                    <ul className="nav navbar-nav">
                        <li className={pathname === "/planner/calendar" ? "active" : ""}>
                            <Link to="/planner/calendar">
                                <i className="icon-calendar"/>&nbsp;
                                Calendar
                            </Link>
                        </li>
                        <li className={pathname === "/planner/classes" ? "active" : ""}>
                            <Link to="/planner/classes">
                                <i className="icon-book"/>&nbsp;
                                Classes
                            </Link>
                        </li>
                        <li className={pathname === "/planner/materials" ? "active" : ""}>
                            <Link to="/planner/materials">
                                <i className="icon-briefcase"/>&nbsp;
                                Materials
                            </Link>
                        </li>
                        <li className={pathname === "/planner/grades" ? "active" : ""}>
                            <Link to="/planner/grades">
                                <i className="icon-bar-chart"/>&nbsp;
                                Grades
                            </Link>
                        </li>
                    </ul> :
                    ""
                }

                { isAuthenticated ?
                    <ul className="nav navbar-nav navbar-right">
                        <ReminderMenu/>
                        <li className={pathname === "/settings" ? "active dropdown" : "dropdown"}>
                            <a href="#" className="dropdown-toggle" data-toggle="dropdown">
                                <i className="icon-tasks"/>&nbsp;
                                Account
                                &nbsp;<b className="caret"/>
                            </a>
                            <ul className="dropdown-menu">
                                <li>
                                    <Link to="/settings">
                                        <i className="icon-cog"/>&nbsp;
                                        Settings
                                    </Link>
                                </li>
                                <li className="divider"/>
                                <li>
                                    <Link to="/logout">
                                        <i className="icon-signout"/>&nbsp;
                                        Logout
                                    </Link>
                                </li>
                            </ul>
                        </li>
                    </ul> :
                    <ul className="nav navbar-nav navbar-right">
                        <li className={pathname === "/register" ? "active" : ""}>
                            <Link to="/register">
                                <i className="icon-user"/>&nbsp;
                                Register
                            </Link>
                        </li>
                        <li className={pathname === "/login" ? "active" : ""}>
                            <Link to="/login">
                                <i className="icon-signin"/>&nbsp;
                                Login
                            </Link>
                        </li>
                    </ul>
                }
            </div>
        );
    };

    render = () => {
        return (
            <header className="navbar navbar-default navbar-fixed-top hidden-print" id="navbar">
                <nav className="navbar-container" id="navbar-container">
                    <div className="navbar-header">
                        <button type="button" className="navbar-toggle" data-toggle="collapse"
                                data-target=".navbar-collapse">
                            <span className="sr-only">Navigation</span>
                            <span className="icon-bar"></span>
                            <span className="icon-bar"></span>
                            <span className="icon-bar"></span>
                        </button>

                        <Link to="/" className="navbar-brand">
                            <img src={process.env.PUBLIC_URL + '/assets/img/logo.png'} alt="Logo"/>
                                    <span id="version-badge" className="badge badge-yellow">
                                        <small>{process.env.REACT_APP_PROJECT_VERSION}</small>
                                    </span>
                        </Link>
                    </div>

                    {this.buildHeaderNavigation()}
                </nav>
            </header>
        );
    }
}


Header.propTypes = {
    user: PropTypes.shape({
        firstName: PropTypes.string
    }),
    token: PropTypes.string
};

const mapStateToProps = ({user, authentication}) => ({
    user: getAuthenticatedUser({user, authentication}),
    token: authentication.token
});

export default withRouter(connect(mapStateToProps)(Header));
