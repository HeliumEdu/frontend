import React, {Component} from "react";

export default class Grades extends Component {
    render = () => {
        return (
            <div className="main-container" id="main-container">
                <div className="container">
                    <div className="page-content">
                        <div className="page-header">
                            <h1>
                                Grades
                                <small>
                                    <i className="icon-double-angle-right"/>
                                    &nbsp;track your progress
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
