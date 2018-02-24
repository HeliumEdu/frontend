import React from "react";
import ReactDOM from "react-dom";
import {Provider} from "react-redux";
import {MemoryRouter} from "react-router-dom";
import configureStore from "./../../redux";
import Forgot from "./forgot";

const store = configureStore();

it('renders without crashing', () => {
    const div = document.createElement('div');
    ReactDOM.render(
        <Provider store={store}>
            <MemoryRouter>
                <Forgot/>
            </MemoryRouter>
        </Provider>
        , div);
    ReactDOM.unmountComponentAtNode(div);
});
