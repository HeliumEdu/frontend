import React from "react";

// TODO: build this out to be a stateful React component

const ReminderMenu = () => {
    return (
        <li className="green hidden-xs">
            <a data-toggle="dropdown" className="dropdown-toggle" href="#">
                <i className="icon-bell-alt"/>&nbsp;
                <span id="reminder-bell-alt-count" className="badge badge-success to-hide"/>
            </a>

            <ul className="pull-right dropdown-navbar dropdown-menu dropdown-caret dropdown-close">
                <li className="dropdown-header">
                    <i className="icon-bell"/>&nbsp;
                    <span id="reminder-bell-count"/></li>
            </ul>
        </li>
    );
};

export default ReminderMenu;
