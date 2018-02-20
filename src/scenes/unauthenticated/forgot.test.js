import React from "react";
import ReactDOM from "react-dom";
import {MemoryRouter} from "react-router-dom";
import Forgot from "./forgot";

it('renders without crashing', () => {
    const div = document.createElement('div');
    ReactDOM.render(
        <MemoryRouter>
            <Forgot/>
        </MemoryRouter>
        , div);
    ReactDOM.unmountComponentAtNode(div);
});
