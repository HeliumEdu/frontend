import React from "react";
import {Redirect, Route, Switch} from "react-router-dom";
import Calendar from "../../scenes/authenticated/calendar";
import Classes from "../../scenes/authenticated/classes";
import Materials from "../../scenes/authenticated/materials";
import Grades from "../../scenes/authenticated/grades";
import NotFound from "../../scenes/unauthenticated/not-found";

const PlannerRoutes = () => (
    <Switch>
        <Route exact path="/planner/calendar" component={Calendar}/>
        <Route exact path="/planner/classes" component={Classes}/>
        <Route exact path="/planner/materials" component={Materials}/>
        <Route exact path="/planner/grades" component={Grades}/>
        <Redirect exact path="/planner" to="/planner/calendar"/>
        <Route exact path="/planner/*" component={NotFound}/>
    </Switch>
);

export default PlannerRoutes;
