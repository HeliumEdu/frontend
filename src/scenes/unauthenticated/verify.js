import {Component} from "react";
import {connect} from "react-redux";
import {verify, VERIFY_USER} from "../../redux/modules/user";

class Verify extends Component {
    componentWillMount = () => {
        this.props.verify(this.props.history);
    };

    render = () => {
        return null;
    }
}

const mapStateToProps = ({user}) => ({
    errors: user.errors[VERIFY_USER],
    messages: user.messages[VERIFY_USER]
});

export default connect(mapStateToProps, {verify})(Verify);
