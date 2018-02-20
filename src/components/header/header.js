import React, {Component} from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import {Link} from "react-router-dom";
import {getAuthenticatedUser} from "../../redux/modules/user";

class Header extends Component {
    static links = [
        {
            name: 'Calendar',
            link: '/planner/calendar',
            authenticated: true,
            mainNav: true
        },
        {
            name: 'Classes',
            link: '/planner/classes',
            authenticated: true,
            mainNav: true
        },
        {
            name: 'Materials',
            link: '/planner/materials',
            authenticated: true,
            mainNav: true
        },
        {
            name: 'Grades',
            link: '/planner/grades',
            authenticated: true,
            mainNav: true
        },
        {
            name: 'Settings',
            link: '/settings',
            authenticated: true,
            mainNav: false
        },
        {
            name: 'Logout',
            link: '/logout',
            authenticated: true,
            mainNav: false
        },
        {
            name: 'Register',
            link: '/login',
            authenticated: false,
            mainNav: false
        },
        {
            name: 'Login',
            link: '/login',
            authenticated: false,
            mainNav: false
        }
    ];

    buildNavigation = () => {
        return (
            <ul>
                {Header.links.filter(link => link.authenticated === !!this.props.token).map(link => (
                    <li key={link.name}>
                        {link.link && <Link to={link.link}>{link.name}</Link>}
                        {link.onClick && <a href="javascript:void(null);" onClick={link.onClick}>{link.name}</a>}
                    </li>
                ))}
            </ul>
        );
    };

    render = () => {
        return (
            <header className="clearfix">
                <strong className="logo left">MKRN Starter</strong>
                <nav
                    className="main-navigation right">
                    {this.buildNavigation()}
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

export default connect(mapStateToProps)(Header);
