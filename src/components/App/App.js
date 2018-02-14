import React, {Component} from "react";
import {BrowserRouter as Router, Route} from "react-router-dom";
import {browserHistory} from "react-router";
import Header from "../Header/Header";
import Footer from "../Footer/Footer";
import Home from "../../scenes/Home/Home";
import Login from "../../scenes/Login/Login";
import Settings from "../../scenes/Settings/Settings";
import "./App.css";

function requireAuth(nextState, replace) {
    // TBD
}

class App extends Component {
    render() {
        return (
            <Router>
                <Header />

                <Route name="home" exact path="/" component={Home}/>

                <Route name="login" exact path="/login" component={Login}/>

                <Route name="settings" exact path="/settings" component={Settings} onEnter={requireAuth}/>

                <Footer />
            </Router>
        )
    }
}
export default App;
