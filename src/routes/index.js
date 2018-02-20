import React from "react";
import {Route, Switch} from "react-router-dom";
import Home from "../scenes/unauthenticated/static/home";
import Register from "../scenes/unauthenticated/register";
import Verify from "../scenes/unauthenticated/verify";
import Login from "../scenes/unauthenticated/login";
import Logout from "../scenes/unauthenticated/logout";
import Forgot from "../scenes/unauthenticated/forgot";
import NotFound from "../scenes/unauthenticated/not-found";
import Support from "../scenes/unauthenticated/static/support";
import Terms from "../scenes/unauthenticated/static/terms";
import Privacy from "../scenes/unauthenticated/static/privacy";
import Press from "../scenes/unauthenticated/static/press";
import About from "../scenes/unauthenticated/static/about";
import Contact from "../scenes/unauthenticated/static/contact";
import RequireAuth from "./require-auth";
import PlannerRoutes from "./authenticated/planner";
import SettingsRoutes from "./authenticated/settings";

const TopLevelRoutes = () => (
    <Switch>
        <Route exact path="/" component={Home}/>
        <Route exact path="/register" component={Register}/>
        <Route exact path="/verify" component={Verify}/>
        <Route exact path="/login" component={Login}/>
        <Route exact path="/logout" component={Logout}/>
        <Route exact path="/forgot" component={Forgot}/>
        <Route path="/planner" component={RequireAuth(PlannerRoutes)}/>
        <Route path="/settings" component={RequireAuth(SettingsRoutes)}/>
        <Route exact path="/support" component={Support}/>
        <Route exact path="/terms" component={Terms}/>
        <Route exact path="/privacy" component={Privacy}/>
        <Route exact path="/press" component={Press}/>
        <Route exact path="/about" component={About}/>
        <Route exact path="/contact" component={Contact}/>
        <Route component={NotFound}/>
    </Switch>
);

export default TopLevelRoutes;
