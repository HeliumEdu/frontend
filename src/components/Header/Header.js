import React, {Component} from "react";
import {Link} from "react-router-dom";
import "./Header.css";

class Header extends Component {
    render() {
        return (
            <header>
                <ul id="headerButtons">
                    <li className="navButton"><Link to="/">Home</Link></li>
                    <li className="navButton"><Link to="/about">About</Link></li>
                </ul>
            </header>
        )
    }
}
export default Header;