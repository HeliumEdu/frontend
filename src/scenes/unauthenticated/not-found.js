import React, {Component} from "react";
import {Link} from "react-router-dom";

export default class NotFound extends Component {
    render = () => {
        return (
            <div className="main-container">
                <div className="container">
                    <div className="page-content">
                        <div className="row">
                            <div className="col-sm-10 col-sm-offset-1">
                                <div className="error-container">
                                    <div className="well">
                                        <h1 className="grey lighter smaller">
                                            <img src={process.env.PUBLIC_URL + '/assets/img/logo_square.png'} width="50" height="50"
                                                 className="logo-icon"/>&nbsp;
                                            404 Page Not Found
                                        </h1>

                                        <hr/>
                                        <h3 className="lighter smaller">We looked everywhere, but we couldn't find that page!</h3>

                                        <div>
                                            <div className="space"></div>
                                            <h4 className="smaller">Try one of the following:</h4>

                                            <ul className="list-unstyled spaced inline bigger-110 margin-15">
                                                <li>
                                                    <i className="icon-hand-right blue"/>&nbsp;
                                                    Check the URL for typos
                                                </li>

                                                <li>
                                                    <i className="icon-hand-right blue"/>&nbsp;
                                                    Email us and let us know the page you were trying to reach
                                                </li>

                                                <li>
                                                    <i className="icon-hand-right blue"/>&nbsp;
                                                    Browse our support pages, just for fun
                                                </li>
                                            </ul>
                                        </div>

                                        <hr/>
                                        <div className="space"></div>

                                        <div className="center">
                                            <Link to="/" className="btn btn-primary">
                                                <i className="icon-home"/>
                                                Home
                                            </Link>&nbsp;

                                            <Link to="#" className="btn btn-grey">
                                                <i className="icon-refresh"/>
                                                Refresh
                                            </Link>&nbsp;
                                            <Link to="/support" className="btn btn-primary">
                                                <i className="icon-question"/>
                                                Support
                                            </Link>&nbsp;
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
}
