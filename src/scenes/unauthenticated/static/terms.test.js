import React from "react";
import ReactDOM from "react-dom";
import {MemoryRouter} from "react-router-dom";
import Terms from "./terms";

it('renders without crashing', () => {
    const div = document.createElement('div');
    ReactDOM.render(
        <MemoryRouter>
            <Terms/>
        </MemoryRouter>
        , div);
    ReactDOM.unmountComponentAtNode(div);
});
