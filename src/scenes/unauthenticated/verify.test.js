import React from "react";
import ReactDOM from "react-dom";
import {MemoryRouter} from "react-router-dom";
import Verify from "./verify";

it('renders without crashing', () => {
    const div = document.createElement('div');
    ReactDOM.render(
        <MemoryRouter>
            <Verify/>
        </MemoryRouter>
        , div);
    ReactDOM.unmountComponentAtNode(div);
});
