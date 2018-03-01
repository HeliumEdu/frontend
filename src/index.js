import React from "react";
import ReactDOM from "react-dom";
import {Provider} from "react-redux";
import {BrowserRouter} from "react-router-dom";
import "normalize.css";
import configureStore from "./redux";
import Header from "./components/header";
import Footer from "./components/footer";
import Routes from "./routes/";
import "bootstrap/dist/css/bootstrap.min.css";
import "./assets/css/vendors/ace.min.css";
import "./assets/css/helium.css";
// import "./assets/js/vendors/ace-extra";
// import "./assets/js/vendors/ace";

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
