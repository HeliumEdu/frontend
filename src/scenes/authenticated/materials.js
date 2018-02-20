import React, {Component} from "react";

export default class Materials extends Component {
    render = () => {
        return (
            <div className="main-container" id="main-container">
                <div className="container">
                    <div className="page-content">
                        <div className="page-header">
                            <h1>
                                Materials
                                <small>
                                    <i className="icon-double-angle-right"/>
                                    &nbsp;manage books and materials for your classes
                                </small>
                            </h1>
                        </div>

                        <div className="row">
                            <div className="col-sm-12">
                                Content
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
}
