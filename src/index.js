import React from "react";
import ReactDOM from "react-dom";
import {Provider} from "react-redux";
import {BrowserRouter} from "react-router-dom";
import "normalize.css";
import configureStore from "./redux";
import Header from "./components/header/header";
import Routes from "./routes/";
import "./assets/css/base.css";

const store = configureStore();

ReactDOM.render((
    <Provider store={store}>
        <BrowserRouter>
            <div className="app-container">
                <Header />
                <main>
                    <Routes />
                </main>
            </div>
        </BrowserRouter>
    </Provider>
), document.getElementById('root'));

module.hot.accept();
