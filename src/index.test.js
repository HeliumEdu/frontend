import React from "react";
import ReactDOM from "react-dom";
import {Provider} from "react-redux";
import {MemoryRouter} from "react-router-dom";
import configureStore from "./redux";
import Header from "./components/header/header";
import Footer from "./components/footer/footer";
import Home from "./scenes/unauthenticated/static/home";

const store = configureStore();

it('renders without crashing', () => {
    const div = document.createElement('div');
    ReactDOM.render(
        <Provider store={store}>
            <MemoryRouter>
                <div>
                    <Header />
                    <main>
                        <Home />
                    </main>
                    <Footer />
                </div>
            </MemoryRouter>
        </Provider>
        , div);
    ReactDOM.unmountComponentAtNode(div);
});
