import React from "react";
import ReactDOM from "react-dom";
import {Provider} from "react-redux";
import {BrowserRouter} from "react-router-dom";
import "normalize.css";
import configureStore from "./redux";
import Header from "./components/header/header";
import Footer from "./components/footer/footer";
import Routes from "./routes/";
import "./assets/css/helium.css";

const store = configureStore();

ReactDOM.render((
    <Provider store={store}>
        <BrowserRouter>
            <div>
                <Header />
                <main>
                    <Routes />
                </main>
                <Footer />
            </div>
        </BrowserRouter>
    </Provider>
), document.getElementById('root'));

module.hot.accept();
