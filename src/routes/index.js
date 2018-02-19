import React from "react";
import {Route, Switch} from "react-router-dom";
import Login from "../scenes/login";
import Logout from "../scenes/logout";
import Register from "../scenes/register";
import ForgotPassword from "../scenes/forgot-password";
import RequireAuth from "./require-auth";
import AuthenticatedRoutes from "./authenticated/";

const TopLevelRoutes = () => (
    <Switch>
        <Route exact path="/" component={() => <div>Home</div>}/>
        <Route exact path="/login" component={Login}/>
        <Route exact path="/logout" component={Logout}/>
        <Route exact path="/register" component={Register}/>
        <Route exact path="/forgot-password" component={ForgotPassword}/>
        <Route path="/dashboard" component={RequireAuth(AuthenticatedRoutes)}/>
        <Route path="*" component={() => <div>Oops, not found</div>}/>
    </Switch>
);

export default TopLevelRoutes;
