import React, {Component} from "react";
import {Link} from "react-router-dom";
import ConnectSidebar from "../../../components/connect-sidebar";

export default class Privacy extends Component {
    render = () => {
        return (
            <div className="main-container" id="main-container">
                <div className="container">
                    <div className="page-content">
                        <div className="page-header">
                            <h1>
                                Privacy Policy
                                <small>
                                    <i className="icon-double-angle-right"/>
                                    &nbsp;how we protect you
                                </small>
                            </h1>
                        </div>

                        <div className="row">
                            <div className="col-sm-9">
                                <div className="helper-container">
                                    <div className="well">
                                        <p>Last updated November 26, 2017</p>

                                        <h1 className="lighter smaller">Acceptance of Policy</h1>

                                        <p>By using the www.HeliumEdu.com web site ("Service"), you are agreeing to the
                                            following policy ("Privacy Policy"), including any subsequent
                                            changes or modifications to them. If you do not agree to this Policy or to
                                            the
                                            Service's <Link to="/terms">Terms of Service</Link>, do not access the
                                            Service.</p>

                                        <h1 className="lighter smaller">General Information</h1>

                                        <p>The website of www.HeliumEdu.com collects information about visitors
                                            and members when
                                            the Service is researched or used. The Service collects the e-mail addresses
                                            of
                                            those who communicate with the Service via e-mail and information
                                            volunteered by the
                                            user. The information collected is used to improve the quality of the
                                            Service and is
                                            not shared with other entities (except to provide products or services at
                                            the user's
                                            request).</p>

                                        <h1 className="lighter smaller">Cookies</h1>

                                        <p>A cookie is a small amount of data, which includes an anonymous
                                            unique identifier,
                                            which is sent from the Services website to the user's browser and stored on
                                            their
                                            computer's hard drive. Cookies are required to use the Service. Cookies will
                                            be used
                                            when a user signs in, to store a user's preferences, and to keep a user
                                            signed in
                                            for a period of time. Cookies used will expire after a period of time, and
                                            cookies
                                            used will be destroyed when the user manually logs out of the
                                            Service.</p>

                                        <h1 className="lighter smaller">Information Collection and Sharing</h1>

                                        <p>Users will be asked to provide their email address when registering for the
                                            Service.
                                            Collected information may be used
                                            for the Service, identification and authentication, research, and to
                                            contact the user.</p>

                                        <p>The Service will never sell, rent, or share personal information with third
                                            parties
                                            without the consent of the user. The Service does reserve the right to
                                            disclosure
                                            certain personal information if the <Link to="/terms">Terms of
                                                Service</Link> have
                                            been
                                            violated, when required by law, or when disclosure is necessary to protect
                                            the
                                            rights of the Service.</p>

                                        <h1 className="lighter smaller">Client Data</h1>

                                        <p>Third party services are used by the Service to provide the necessary
                                            hardware,
                                            software, networking, and storage that make up the Service.</p>

                                        <p>The Service owns all rights to the code and databases that make up
                                            the Service. Data
                                            stored on the Service belongs to the user that authored it, and the user
                                            retains all
                                            rights to that data.</p>

                                        <h1 className="lighter smaller">Disclosure</h1>

                                        <p>The Service may disclose personal information under special
                                            circumstances, such as to
                                            comply with subpoenas or if a user's actions violate the <Link
                                                to="/terms">Terms of Service</Link>.</p>

                                        <h1 className="lighter smaller">Questions</h1>

                                        <p>If you have any questions regarding this Privacy Policy, contact us by <Link
                                            to="/contact">clicking here</Link>.</p>
                                    </div>
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
