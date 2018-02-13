import React, {Component} from "react";
import {BrowserRouter as Router, Route} from "react-router-dom";
import {browserHistory} from "react-router";
import Home from "../../scenes/Home/Home";
import About from "../../scenes/About/About";
import Header from "../Header/Header";
import Footer from "../Footer/Footer";
import "./App.css";

class App extends Component {
    render() {
        return (
            <Router>
                <div>
                    <Header />
                    <Route name="home" exact path="/" component={Home}/>
                    <Route name="about" exact path="/about" component={About}/>
                    <Footer />
                </div>
            </Router>
        )
    }
}
export default App;
