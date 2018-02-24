import {Component} from "react";
import {connect} from "react-redux";
import {verify, VERIFY_USER} from "../../redux/modules/user";
import queryString from "query-string";

class Verify extends Component {
    componentWillMount = () => {
        const parsed = queryString.parse(window.location.search);

        this.props.verify(parsed);
    };
}

const mapStateToProps = ({user}) => ({
    errors: user.errors[VERIFY_USER],
    message: user.messages[VERIFY_USER]
});

export default connect(mapStateToProps, {verify})(Verify);
