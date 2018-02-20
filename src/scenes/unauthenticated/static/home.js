import React, {Component} from "react";
import {Link} from "react-router-dom";
import "./home.css";

export default class Home extends Component {
    render = () => {
        return (
            <div className="main-container" id="main-container">
                <div className="space-8"></div>
                <div id="tour-carousel" className="carousel slide" data-ride="carousel">
                    <ol className="carousel-indicators">
                        <li data-target="#tour-carousel" data-slide-to="0" className="active"></li>
                        <li data-target="#tour-carousel" data-slide-to="1"></li>
                        <li data-target="#tour-carousel" data-slide-to="2"></li>
                        <li data-target="#tour-carousel" data-slide-to="3"></li>
                        <li data-target="#tour-carousel" data-slide-to="4"></li>
                    </ol>
                    <div className="carousel-inner">
                        <div className="item active">
                            <img src={process.env.PUBLIC_URL + '/assets/img/slider_1.png'} className="thumbnail"
                                 alt="Slider 1"/>
                        </div>
                        <div className="item">
                            <img src={process.env.PUBLIC_URL + '/assets/img/slider_2.png'} className="thumbnail"
                                 alt="Slider 2"/>
                        </div>
                        <div className="item">
                            <img src={process.env.PUBLIC_URL + '/assets/img/slider_3.png'} className="thumbnail"
                                 alt="Slider 3"/>
                        </div>
                        <div className="item">
                            <img src={process.env.PUBLIC_URL + '/assets/img/slider_4.png'} className="thumbnail"
                                 alt="Slider 4"/>
                        </div>
                        <div className="item">
                            <img src={process.env.PUBLIC_URL + '/assets/img/slider_5.png'} className="thumbnail"
                                 alt="Slider 5"/>
                        </div>
                    </div>
                    <a className="left carousel-control" href="#tour-carousel" role="button" data-slide="prev"><span
                        className="glyphicon blue glyphicon-chevron-left"/></a>
                    <a className="right carousel-control" href="#tour-carousel" role="button" data-slide="next"><span
                        className="glyphicon blue glyphicon-chevron-right"/></a>
                </div>
                <div className="space-12"></div>
                <div className="row align-center">
                    <p><Link className="btn btn-lg btn-primary" to="/register" role="button"><i
                        className="icon-user"/>
                        Sign Me Up!</Link> <a
                        className="btn btn-lg btn-default hidden-xs" href="#overview"
                        role="button">Read More &raquo;</a></p>
                </div>

                <div id="overview" className="space-32"></div>
                <div className="space-24 hidden-xs"></div>

                <div className="container marketing">
                    <div className="row">
                        <div className="col-lg-4 align-center">
                            <img className="img-circle square-140"
                                 src={process.env.PUBLIC_URL + '/assets/img/circle_1.png'}
                                 alt="Circle 1"/>

                            <h2>Coordinated Calendars</h2>

                            <p>Easily organize and color-coordinate your schedule and schoolwork, capture details about
                                every
                                assignment, and plan your study schedule.</p>

                            <p><a className="btn btn-default" href="#calendars" role="button">Read More &raquo;</a>
                            </p>
                        </div>

                        <div className="space-24 visible-xs"></div>

                        <div className="col-lg-4 align-center">
                            <img className="img-circle square-140"
                                 src={process.env.PUBLIC_URL + '/assets/img/circle_2.png'}
                                 alt="Circle 2"/>

                            <h2>Schedule at a Glance</h2>

                            <p>Categorize your assignments, set up grading scales, and enter details about teachers,
                                room location,
                                schedules, credits, and more!</p>

                            <p><a className="btn btn-default" href="#classes" role="button">Read More &raquo;</a></p>
                        </div>

                        <div className="space-24 visible-xs"></div>

                        <div className="col-lg-4 align-center">
                            <img className="img-circle square-140"
                                 src={process.env.PUBLIC_URL + '/assets/img/circle_3.png'}
                                 alt="Circle 3"/>

                            <h2>Grade Analysis</h2>

                            <p>Constantly up-to-date details about your grades in every class, a breakdown of your
                                progress, and
                                insight into which classes you're acing and what could use improvement.</p>

                            <p><a className="btn btn-default" href="#grades" role="button">Read More &raquo;</a></p>
                        </div>
                    </div>

                    <div className="space-24"></div>

                    <div className="row">
                        <div className="col-lg-4 align-center">
                            <img className="img-circle square-140"
                                 src={process.env.PUBLIC_URL + '/assets/img/circle_4.png'}
                                 alt="Circle 4"/>

                            <h2>Assignment Details</h2>

                            <p>Enter due date and textbook details, add notes to remember later, set a priority level,
                                and record
                                grades when complete.</p>

                            <p><a className="btn btn-default" href="#assignments" role="button">Read More &raquo;</a>
                            </p>
                        </div>

                        <div className="space-24 visible-xs"></div>

                        <div className="col-lg-4 align-center">
                            <img className="img-circle square-140"
                                 src={process.env.PUBLIC_URL + '/assets/img/circle_5.png'}
                                 alt="Circle 5"/>

                            <h2>Materials Organizer</h2>

                            <p>Maintain a list and details of the supplies, books, technology, and equipment you'll need
                                to pick up
                                to be ready for class each semester and each day.</p>

                            <p><a className="btn btn-default" href="#materials" role="button">Read More &raquo;</a>
                            </p>
                        </div>

                        <div className="space-24 visible-xs"></div>

                        <div className="col-lg-4 align-center">
                            <img className="img-circle square-140"
                                 src={process.env.PUBLIC_URL + '/assets/img/circle_6.png'}
                                 alt="Circle 6"/>

                            <h2>Filtered Lists</h2>

                            <p>Sort assignments by class, priority level, due date, materials needed, etc. for an easy
                                way to
                                structure your study time and plan your approach to mastering your courses.</p>

                            <p><a className="btn btn-default" href="#filters" role="button">Read More &raquo;</a></p>
                        </div>
                    </div>

                    <div id="calendars"></div>
                    <hr className="featurette-divider"/>

                    <div className="row featurette">
                        <div className="col-md-7">
                            <h2 className="featurette-heading">Coordinated Calendars.<span className="text-muted">The Home Base.</span>
                            </h2>

                            <p className="lead">
                                Don't worry about trying to remember every homework assignment, project, or test&#8212;
                                use
                                that brainpower to ace your classes and let Helium whip your schedule into shape! Easily
                                organize
                                and color-coordinate your schedule and schoolwork, capture details about every
                                assignment, and plan
                                your study schedule. Keep track of the details of your class, put together your
                                necessary supplies,
                                and catalog things like teacher contact info and class location.
                            </p>

                            <p><Link className="btn btn-sm btn-primary" to="/register" role="button"><i
                                className="icon-user"/>
                                Sign Me Up!</Link> <a className="btn btn-sm btn-default" href="#overview" role="button">Back
                                to Top
                                <i
                                    className="icon-arrow-up icon-on-right"/></a></p>
                        </div>
                        <div className="col-md-5">
                            <img className="featurette-image thumbnail img-responsive"
                                 src={process.env.PUBLIC_URL + '/assets/img/feature_1.png'}
                                 alt="Featured 1"/>
                        </div>
                    </div>

                    <div id="classes"></div>
                    <hr className="featurette-divider"/>

                    <div className="row featurette">
                        <div className="col-md-5">
                            <img className="featurette-image thumbnail img-responsive"
                                 src={process.env.PUBLIC_URL + '/assets/img/feature_2.png'}
                                 alt="Featured 2"/>
                        </div>
                        <div className="col-md-7">
                            <h2 className="featurette-heading">Schedule At A Glance.<span className="text-muted">The Brass Tacks.</span>
                            </h2>

                            <p className="lead">
                                With at-a-glance overviews of your past and present terms and classes, a quick sketch of
                                your schedule is always handy. Categorize your assignments, set up grading scales, and
                                enter details
                                about teachers, room location, schedules, credits, and more!
                            </p>

                            <p className="pull-right"><Link className="btn btn-sm btn-primary" to="/register"
                                                            role="button"><i
                                className="icon-user"/>
                                Sign Me Up!</Link> <a className="btn btn-sm btn-default" href="#overview" role="button">Back
                                to Top<i
                                    className="icon-arrow-up icon-on-right"/></a></p>
                        </div>
                    </div>

                    <div id="grades"></div>
                    <hr className="featurette-divider"/>

                    <div className="row featurette">
                        <div className="col-md-7">
                            <h2 className="featurette-heading">Grade Analysis.<span className="text-muted">The Bottom Line.</span>
                            </h2>

                            <p className="lead">
                                Tired of always wondering how you're doing in a class? Frustrated by trying to calculate
                                your own grades? Record grades as you get them, and Helium takes care of the rest! A
                                full workup of
                                your progress is always just a click away, with constantly up-to-date details about your
                                grades in
                                every class, a breakdown of your progression through the term, and insight into which
                                classes you're
                                acing and what could use improvement. We'll crunch the numbers for you!
                            </p>

                            <p><Link className="btn btn-sm btn-primary" to="/register" role="button"><i
                                className="icon-user"/>
                                Sign Me Up!</Link> <a className="btn btn-sm btn-default" href="#overview" role="button">Back
                                to Top<i
                                    className="icon-arrow-up icon-on-right"/></a></p>
                        </div>
                        <div className="col-md-5">
                            <img className="featurette-image thumbnail img-responsive"
                                 src={process.env.PUBLIC_URL + '/assets/img/feature_3.png'}
                                 alt="Featured 3"/>
                        </div>
                    </div>

                    <div id="assignments"></div>
                    <hr className="featurette-divider"/>

                    <div className="row featurette">
                        <div className="col-md-5">
                            <img className="featurette-image thumbnail img-responsive"
                                 src={process.env.PUBLIC_URL + '/assets/img/feature_4.png'}
                                 alt="Featured 4"/>
                        </div>
                        <div className="col-md-7">
                            <h2 className="featurette-heading">Assignment Details.<span className="text-muted">The Nitty Gritty.</span>
                            </h2>

                            <p className="lead">
                                Never miss an assignment again! Let Helium remember the details of every assignment so
                                you don't have to. Enter due date and textbook details, add notes, set a priority level,
                                and record
                                grades when complete.
                            </p>

                            <p className="pull-right"><Link className="btn btn-sm btn-primary" to="register"
                                                            role="button"><i
                                className="icon-user"/>
                                Sign Me Up!"</Link> <a className="btn btn-sm btn-default" href="#overview"
                                                       role="button">Back to Top<i
                                className="icon-arrow-up icon-on-right"/></a></p>
                        </div>
                    </div>

                    <div id="materials"></div>
                    <hr className="featurette-divider"/>

                    <div className="row featurette">
                        <div className="col-md-7">
                            <h2 className="featurette-heading">Materials Organizer.<span className="text-muted">The Meat & Potatoes.</span>
                            </h2>

                            <p className="lead">
                                Everything you need for every class in one place! Helium will maintain a list of the
                                supplies, books, technology, and equipment you'll need to pick up to be ready for class
                                each
                                semester and each day. Make textbook resale a snap by recording details about each book,
                                such as
                                seller, price, and condition.
                            </p>

                            <p><Link className="btn btn-sm btn-primary" to="/register" role="button"><i
                                className="icon-user"/>
                                Sign Me Up!</Link> <a className="btn btn-sm btn-default" href="#overview" role="button">Back
                                to Top<i
                                    className="icon-arrow-up icon-on-right"/></a></p>
                        </div>
                        <div className="col-md-5">
                            <img className="featurette-image thumbnail img-responsive"
                                 src={process.env.PUBLIC_URL + '/assets/img/feature_5.png'}
                                 alt="Featured 5"/>
                        </div>
                    </div>

                    <div id="filters"></div>
                    <hr className="featurette-divider"/>

                    <div className="row featurette">
                        <div className="col-md-5">
                            <img className="featurette-image thumbnail img-responsive"
                                 src={process.env.PUBLIC_URL + '/assets/img/feature_6.png'}
                                 alt="Featured 6"/>
                        </div>
                        <div className="col-md-7">
                            <h2 className="featurette-heading">Filtered Lists.<span className="text-muted">The Nuts & Bolts.</span>
                            </h2>

                            <p className="lead">
                                In addition to viewing your assignments and events in the calendar, manage your schedule
                                in List View for a concise snapshot of your assignment lineup. Sort assignments by
                                class, priority
                                level, due date, materials needed, etc. for an easy way to structure your study time and
                                plan your
                                approach to mastering your courses.
                            </p>

                            <p className="pull-right"><Link className="btn btn-sm btn-primary" to="/register"
                                                            role="button"><i
                                className="icon-user"/>
                                Sign Me Up!"</Link> <a className="btn btn-sm btn-default" href="#overview"
                                                       role="button">Back to Top<i
                                className="icon-arrow-up icon-on-right"/></a></p>
                        </div>
                    </div>

                    <hr className="featurette-divider"/>

                    <div className="row featurette">
                        <div className="col-md-7">
                            <h2 className="featurette-heading">The Delightful Dingo. <span
                                className="text-muted">Our Mascot.</span>
                            </h2>

                            <p className="lead">
                                Because.
                                <br/><br/>
                                Dingos primarily are wild neighbors to our Aussie friends, though
                                they can also be found in parts of southeast Asia. They have a bit of a love/hate
                                relationship with
                                their human neighbors, who partially consider them pests and partially credit them for
                                keeping
                                rabbits, rats, and kangaroos (yes, kangaroos) at bay.
                                <br/><br/>
                                An iconic aspect of Australian culture and history, we also think Dingos are cool
                                because of their
                                complex conversation system that, unlike that of Fido who just noticed the mailman out
                                front, is
                                only 5% barking.
                            </p>

                            <p><Link className="btn btn-sm btn-primary" to="/register" role="button"><i
                                className="icon-user"/>
                                Sign Me Up!</Link> <a
                                className="btn btn-sm btn-default" href="#overview" role="button">Back to Top
                                <i
                                    className="icon-arrow-up icon-on-right"/></a></p>
                        </div>
                        <div className="col-md-5">
                            <img className="featurette-image img-responsive img-circle"
                                 src={process.env.PUBLIC_URL + '/assets/img/dingo.png'}
                                 alt="Mascot"/>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
}
