import React, {Component} from "react";
import {Link} from "react-router-dom";

export default class Footer extends Component {
    static links = [
        {
            name: 'Tour',
            link: '/'
        },
        {
            name: 'Terms',
            link: '/terms'
        },
        {
            name: 'Privacy',
            link: '/privacy'
        },
        {
            name: 'Support',
            link: '/support'
        },
        {
            name: 'Press',
            link: '/press'
        },
        {
            name: 'About',
            link: '/about'
        },
        {
            name: 'Contact',
            link: '/contact'
        }
    ];


    buildFooterNavigation = () => {
        return (
            <ul>
                {Footer.links.map(link => (
                    <li key={link.name}>
                        {link.link && <Link to={link.link}>{link.name}</Link>}
                    </li>
                ))}
            </ul>
        );
    };

    componentDidMount = () => {
        (function () {
            var uv = document.createElement('script');
            uv.type = 'text/javascript';
            uv.async = true;
            uv.src = '//widget.uservoice.com/w7OD33G1CR78e0pGaGfw.js';
            var s = document.getElementsByTagName('script')[0];
            s.parentNode.insertBefore(uv, s);
        })();
    };

    render = () => {
        return (
            <footer className="hidden-print">
                <div className="container">
                    <div className="row social-footer">
                        <div className="pull-right">
                            <a href="https://github.com/HeliumEdu" className="white" target="_blank"
                               rel="noopener noreferrer">
                                <img src={process.env.PUBLIC_URL + '/assets/img/github.png'} alt="Twitter" width="38"
                                     height="38" className="inline"/>&nbsp;
                            </a>
                            <a href="http://www.twitter.com/heliumstudents" className="white" target="_blank"
                               rel="noopener noreferrer">
                                <img src={process.env.PUBLIC_URL + '/assets/img/twitter.png'} alt="Twitter" width="38"
                                     height="38" className="inline"/>&nbsp;
                            </a>
                            <a href="http://www.facebook.com/heliumstudents" className="white" target="_blank"
                               rel="noopener noreferrer">
                                <img src={process.env.PUBLIC_URL + '/assets/img/facebook.png'} alt="Facebook" width="38"
                                     height="38" className="inline"/>&nbsp;
                            </a>
                            <a href="http://blog.heliumedu.com" className="white" target="_blank"
                               rel="noopener noreferrer">
                                <img src={process.env.PUBLIC_URL + '/assets/img/tumblr.png'} alt="Blog" width="38"
                                     height="38" className="inline"/>&nbsp;
                            </a>
                        </div>
                    </div>
                </div>

                <div className="container">
                    <span>Copyright &copy; {new Date().getFullYear()} Helium Edu</span>

                    <nav>
                        {this.buildFooterNavigation()}
                    </nav>
                </div>
            </footer>
        );
    }
}
