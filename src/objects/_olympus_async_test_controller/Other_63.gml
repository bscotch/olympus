if  (async_load[?"id"] == _user_feedback_handle)
{	
    if (async_load[?"status"])
        {
			var _user_input = async_load[?"result"];
			if (string_lower(_user_input) == string_lower(_olympus_user_feedback_confirm_message)){
				_current_test.resolve();
	        }
			else{
				//User changed the default input to fail the test
				_current_test.reject({message:_user_input}, olympus_error_code.user_rejection);
			}
    }
	else{
		_current_test.reject({message:"User cancelled the prompt!"}, olympus_error_code.user_cancellation);
	}
}