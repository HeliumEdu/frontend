import React, {Component} from "react";
import ConnectSidebar from "../../../components/connect-sidebar";
import "./press.css";

export default class Press extends Component {
    render = () => {
        return (
            <div className="main-container" id="main-container">
                <div className="container">
                    <div className="page-content">
                        <div className="page-header">
                            <h1>
                                Press
                                <small>
                                    <i className="icon-double-angle-right"/>
                                    &nbsp;content for press releases
                                </small>
                            </h1>
                        </div>

                        <div className="row">
                            <div className="col-sm-9">
                                <img src={process.env.PUBLIC_URL + '/assets/img/logo_full_white.png'}
                                     className="about-logo" alt=""/>

                                <p>
                                    The content below is freely available for use in advertising, press releases, and to
                                    help spread the word about Helium! If you have questions, <a
                                    href="https://www.facebook.com/heliumstudents" target="_blank"
                                    rel="noopener noreferrer">find us on
                                    Facebook</a>, <a href="https://www.twitter.com/heliumstudents" target="_blank"
                                                     rel="noopener noreferrer">stalk
                                    us on Twitter</a>, or just
                                    <a href={"mailto:" + process.env.REACT_APP_PROJECT_EMAIL }>get in touch via
                                        email</a>!</p>

                                <h3>Logos and Images</h3>

                                <div className="row">
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/logo_square.png'}
                                        target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/logo_square.png'}
                                        className="thumbnail max-width" alt=""/></a></div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/logo_square_blue.png'}
                                        target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/logo_square_blue.png'}
                                        className="thumbnail max-width" alt=""/></a></div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/logo_full_white.png'}
                                        target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/logo_full_white.png'}
                                        className="thumbnail max-width" alt=""/></a></div>
                                </div>
                                <div className="row">
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/logo_full_blue.png'}
                                        target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/logo_full_blue.png'}
                                        className="thumbnail max-width" alt=""/></a></div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/email_logo.png'}
                                        target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/email_logo.png'}
                                        className="thumbnail max-width" alt=""/></a>
                                    </div>
                                    <div className="col-sm-4"><a href={process.env.PUBLIC_URL + '/assets/img/logo.png'}
                                                                 target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/logo.png'}
                                        className="thumbnail max-width light-blue-bg" alt=""/></a></div>
                                </div>

                                <h3>Screenshots</h3>

                                <div className="row">
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/slider_2.png'} target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/slider_2.png'}
                                        className="thumbnail max-width" alt=""/></a></div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/slider_3.png'} target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/slider_3.png'}
                                        className="thumbnail max-width" alt=""/></a>
                                    </div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/slider_4.png'} target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/slider_4.png'}
                                        className="thumbnail max-width light-blue-bg" alt=""/></a></div>
                                </div>
                                <div className="row">
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/slider_5.png'} target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/slider_5.png'}
                                        className="thumbnail max-width" alt=""/></a></div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/filter_view.png'}
                                        target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/filter_view.png'}
                                        className="thumbnail max-width" alt=""/></a>
                                    </div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/feature_4.png'} target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/feature_4.png'}
                                        className="thumbnail max-width light-blue-bg" alt=""/></a></div>
                                </div>
                                <div className="row">
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/materials.png'} target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/materials.png'}
                                        className="thumbnail max-width" alt=""/></a></div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/grades_1.png'} target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/grades_1.png'}
                                        className="thumbnail max-width" alt=""/></a>
                                    </div>
                                    <div className="col-sm-4"><a
                                        href={process.env.PUBLIC_URL + '/assets/img/grades_2.png'} target="_blank"><img
                                        src={process.env.PUBLIC_URL + '/assets/img/grades_2.png'}
                                        className="thumbnail max-width light-blue-bg" alt=""/></a></div>
                                </div>
                            </div>

                            <ConnectSidebar/>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
}
