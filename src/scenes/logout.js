import {Component} from "react";
import {connect} from "react-redux";
import {logout} from "../redux/modules/authentication";

class Logout extends Component {

    render = () => {
        this.props.logout();

        console.log("Logout submitted");

        return null;
    }
}

const mapStateToProps = ({authentication}) => ({
    token: authentication.token
});

export default connect(mapStateToProps, {logout})(Logout);
