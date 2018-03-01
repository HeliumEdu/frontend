import React, {Component} from "react";
import ConnectSidebar from "../../../components/connect-sidebar";

export default class Contact extends Component {
    componentDidMount = () => {
        var uv = document.createElement('script');
        uv.type = 'text/javascript';
        uv.async = true;
        uv.src = '//widget.uservoice.com/w7OD33G1CR78e0pGaGfw.js';
        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(uv, s);
    };

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
