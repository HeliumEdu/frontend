import React, {Component} from "react";
import ConnectSidebar from '../../../components/connect-sidebar';
import './about.css';

export default class About extends Component {
    render = () => {
        return (
            <div className="main-container" id="main-container">
                <div className="container">
                    <div className="page-content">
                        <div className="page-header">
                            <h1>
                                About
                                <small>
                                    <i className="icon-double-angle-right"/>
                                    &nbsp;who we are
                                </small>
                            </h1>
                        </div>

                        <div className="row">
                            <div className="col-sm-9">
                                <img src={process.env.PUBLIC_URL + '/assets/img/logo_full_white.png'}
                                     className="about-logo" alt=""/>

                                <h2>The Basics</h2>

                                <p>Short and simple: Helium allows you to ditch the physical planner and take control of your
                                    schoolwork.</p>

                                <p>And because we like you and want to make this work, we're also throwing in a few extras. Those
                                    pesky grades that are so hard to monitor? We've got your back. Ever-changing due dates? No
                                    problem. A quick look at your progress through a semester? Just a click away.</p>

                                <p>We could keep going, but that would contradict this section's title, eh?</p>

                                <h2>The Back Story</h2>

                                <p>Helium has its origins in Get Organized, an open source, cross-platform digital planner developed
                                    by a frustrated Software Engineering in his sophomore year of college. Alex Laird's frustrations
                                    weren't from a lack of programs claiming to help students declutter their academic calendar, but
                                    because all of these tools were limited and incomplete. So he did what most Software Engineers
                                    do when they face this problem&#8212;he made his own.</p>

                                <p>But what started as a tool made for himself was soon noticed by his friends, so he made it
                                    available for download from his personal website. Within a few weeks, Get Organized was
                                    receiving the recognition of big-name tech sites like CNET's Download.com and Lifehacker, and in
                                    no time at all Get Organized was being used by tens of thousands of students worldwide. As it
                                    turned out, Alex wasn't the only student facing these organizational frustrations.</p>

                                <h2>The Now</h2>

                                <p>Fast-forward a few years; Get Organized was due a professional rework from the ground up, this
                                    time as an intuitive and modern set of websites and apps.</p>

                                <p>Enter Helium, the natural evolution of Get Organized for the modern student, rebuilt from the
                                    ground up by a professional team with a desire to see students succeed in every area of their
                                    life.</p>

                                <p>For the most recent happenings and updates about Helium, be sure to <a
                                    href="http://blog.heliumedu.com" target="_blank" rel="noopener noreferrer">check out our blog</a>. We update that with
                                    news about upcoming features, promotions, notes about new releases, and more!</p>

                                <p>If you have questions, <a href="https://www.facebook.com/heliumstudents" target="_blank" rel="noopener noreferrer">find us
                                    on Facebook</a>, <a href="https://www.twitter.com/heliumstudents" target="_blank" rel="noopener noreferrer">stalk us on
                                    Twitter</a>, or just <a href={"mailto:" + process.env.REACT_APP_PROJECT_EMAIL}>get in touch via
                                    email</a>!</p>
                            </div>

                            <ConnectSidebar/>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
}
