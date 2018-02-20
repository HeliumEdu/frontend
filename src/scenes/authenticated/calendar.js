import React, {Component} from "react";

export default class Calendar extends Component {
    render = () => {
        return (
            <div className="main-container">
                <div className="page-content">
                    <div className="row" id="planner-row">
                        <div className="col-xs-12">
                            <div id="calendar-loading">
                                <div id="loading-calendar"></div>
                            </div>
                            <div id="calendar"></div>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
}
