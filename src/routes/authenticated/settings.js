import React from "react";
import {Route, Switch} from "react-router-dom";
import Settings from "../../scenes/authenticated/settings";
import NotFound from "../../scenes/not-found";

const SettingsRoutes = () => (
    <Switch>
        <Route exact path="/settings" component={Settings}/>
        <Route exact path="/settings/*" component={NotFound}/>
    </Switch>
);

export default SettingsRoutes;
