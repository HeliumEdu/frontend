import React from "react";
import {Route, Switch} from "react-router-dom";

const AuthenticatedRoutes = () => (
    <Switch>
        <Route exact path="/dashboard/main" component={() => <div>Welcome to the dashboard</div>}/>
        <Route exact path="/dashboard/profile" component={() => <div>Welcome to the profile</div>}/>
    </Switch>
);

export default AuthenticatedRoutes;
