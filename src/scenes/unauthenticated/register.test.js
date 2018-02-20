import React from "react";
import ReactDOM from "react-dom";
import {MemoryRouter} from "react-router-dom";
import Register from "./register";

it('renders without crashing', () => {
    const div = document.createElement('div');
    ReactDOM.render(
        <MemoryRouter>
            <Register/>
        </MemoryRouter>
        , div);
    ReactDOM.unmountComponentAtNode(div);
});
