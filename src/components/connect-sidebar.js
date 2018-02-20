import React, {Component} from "react";
import {withRouter, Link} from "react-router-dom";

class ConnectSidebar extends Component {

    render = () => {
        const {pathname} = this.props.location;

        return (
            <div className="col-sm-3">
                <h3 className="lighter smaller">Connect with Us</h3>

                { pathname !== '/contact' ?
                    <div className="infobox infobox-blue">
                        <div className="infobox-icon">
                            <i className="icon-envelope"/>
                        </div>

                        <div className="infobox-data">
                            <Link className="infobox-data-number" to="/contact">Send us</Link>

                            <div className="infobox-content">Feedback</div>
                        </div>
                    </div> :
                    ""
                }

                <div className="infobox infobox-blue">
                    <div className="infobox-icon">
                        <i className="icon-rss"/>
                    </div>

                    <div className="infobox-data">
                        <a className="infobox-data-number" href="http://blog.heliumedu.com"
                           target="_blank" rel="noopener noreferrer">Read our</a>

                        <div className="infobox-content">Blog</div>
                    </div>
                </div>

                <div className="infobox infobox-blue">
                    <div className="infobox-icon">
                        <i className="icon-twitter"/>
                    </div>

                    <div className="infobox-data">
                        <a className="infobox-data-number" href="https://www.twitter.com/heliumstudents"
                           target="_blank" rel="noopener noreferrer">Follow us on</a>

                        <div className="infobox-content">Twitter</div>
                    </div>
                </div>

                <div className="infobox infobox-blue">
                    <div className="infobox-icon">
                        <i className="icon-facebook"/>
                    </div>

                    <div className="infobox-data">
                        <a className="infobox-data-number" href="https://www.facebook.com/heliumstudents"
                           target="_blank" rel="noopener noreferrer">Like us on</a>

                        <div className="infobox-content">Facebook</div>
                    </div>
                </div>
            </div>
        );
    }
}

export default withRouter(ConnectSidebar);