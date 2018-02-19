import React from "react";
import {Route, Switch} from "react-router-dom";
import Home from "../scenes/home";
import Register from "../scenes/register";
import Verify from "../scenes/verify";
import Login from "../scenes/login";
import Logout from "../scenes/logout";
import Forgot from "../scenes/forgot";
import NotFound from "../scenes/not-found";
import Support from "../scenes/support";
import Terms from "../scenes/terms";
import Privacy from "../scenes/privacy";
import Press from "../scenes/press";
import About from "../scenes/about";
import Contact from "../scenes/contact";
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
