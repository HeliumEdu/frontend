import React, {Component} from "react";
import PropTypes from "prop-types";
import {connect} from "react-redux";
import {Link} from "react-router-dom";
import {getAuthenticatedUser} from "../../redux/modules/user";
import {mobileBreakpoint} from "../../util/ui-constants";

class Header extends Component {
    state = {
        isMobile: window.innerWidth <= mobileBreakpoint,
        mobileNavOpen: false
    };

    componentWillMount = () => {
        window.addEventListener('resize', this.mobileCheck);
    };

    componentWillUnmount = () => {
        window.removeEventListener('resize', this.mobileCheck);
    };

    mobileCheck = () => this.setState({isMobile: window.innerWidth <= mobileBreakpoint});

    buildNavigation = () => {
        const {user} = this.props;
        const links = [
            {
                name: 'Dashboard',
                link: '/dashboard/main',
                authenticated: true
            },
            {
                name: (user && user.firstName) || 'Profile',
                link: '/dashboard/profile',
                authenticated: true
            },
            {
                name: 'Sign out',
                link: '/logout',
                authenticated: true
            },
            {
                name: 'Sign in',
                link: '/login',
                authenticated: false
            },
            {
                name: 'Register',
                link: '/register',
                authenticated: false
            }
        ];

        return (
            <ul>
                {links.filter(link => link.authenticated === !!this.props.token).map(link => (
                    <li key={link.name}>
                        {link.link && <Link to={link.link}>{link.name}</Link>}
                        {link.onClick && <a href="javascript:void(null);" onClick={link.onClick}>{link.name}</a>}
                    </li>
                ))}
            </ul>
        );
    };

    toggleMobileNav = () => this.setState({mobileNavOpen: !this.state.mobileNavOpen});

    render() {
        const {isMobile, mobileNavOpen} = this.state;

        return (
            <header className="clearfix">
                <strong className="logo left">MKRN Starter</strong>
                {isMobile &&
                <a
                    href="javascript:void(null);"
                    role="button"
                    className="mobile-nav-toggle clearfix right material-icons"
                    onClick={this.toggleMobileNav}
                    aria-label="Toggle navigation"
                >
                    {mobileNavOpen ? 'close' : 'menu'}
                </a>
                }
                <nav
                    className={`main-navigation right ${isMobile ? `mobile ${mobileNavOpen ? 'is-expanded' : ''}` : ''}`}>
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
