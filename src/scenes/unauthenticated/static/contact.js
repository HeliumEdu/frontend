import React, {Component} from "react";
import ConnectSidebar from "../../../components/connect-sidebar";

export default class Contact extends Component {
    render = () => {
        return (
            <div className="main-container" id="main-container">
                <div className="container">
                    <div className="page-content">
                        <div className="page-header">
                            <h1>
                                Contact
                                <small>
                                    <i className="icon-double-angle-right"/>
                                    &nbsp;we'd love to hear from you
                                </small>
                            </h1>
                        </div>

                        <div className="row">
                            <div className="col-sm-9">
                                <div data-uv-embed="contact" data-uv-screenshot_enabled="false"></div>
                            </div>

                            <ConnectSidebar/>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
}
