import React from "react";
import {render} from "react-dom";
import {Provider} from "react-redux";
import {store, configureFakeBackend} from "./helpers";
import {App} from "./scenes/App";

// setup fake backend
configureFakeBackend();

render(
    <Provider store={store}>
        <App />
    </Provider>,
    document.getElementById('root')
);