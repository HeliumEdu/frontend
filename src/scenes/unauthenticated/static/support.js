import {Component} from "react";

export default class Support extends Component {
    componentWillMount = () => {
        window.location.replace("https://heliumedu.uservoice.com");
    };

    // TODO: need to find a way to remove the /support from history so "back" works properly
}
