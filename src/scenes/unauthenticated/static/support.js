import {Component} from "react";

export default class Support extends Component {
    componentWillMount = () => {
        window.location.replace("https://heliumedu.uservoice.com");
    };

    render = () => {
        return null;
    };
}
