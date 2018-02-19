import {Component} from "react";
import {connect} from "react-redux";
import {logout} from "../redux/modules/authentication";

class Logout extends Component {
    render = () => {
        this.props.logout();

        return null;
    }
}

const mapStateToProps = ({authentication}) => ({});

export default connect(mapStateToProps, {logout})(Logout);
