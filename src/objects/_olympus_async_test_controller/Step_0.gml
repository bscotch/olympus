///@desc Evaluates whether there is a suite that is in progress
var _suite_is_running = function(){
	return  variable_global_exists("_olympus_test_manager")
						&&  is_struct(global._olympus_test_manager)
						&&  global._olympus_test_manager._startTime
						&& 	!global._olympus_test_manager._completion_time;
}

if (_suite_is_running()) {
	while (_interval_between_tests_counter <= 0 && _suite_is_running()){
		_current_test = global._olympus_test_manager.get_current_test();
		if (_current_test.status == olympus_test_status_unstarted){					
			var this_test_summary = _current_test.get_summary();
			if (is_method(_function_to_call_on_test_start)){
				_function_to_call_on_test_start(this_test_summary);
			}
			if (global._olympus_test_manager._bail_on_fail_or_crash && global._olympus_summary_manager.has_failure_or_crash()){
				_current_test.disabled = true;
			}			
			_current_test.run();
		}

		if (_current_test.status == olympus_test_status_running ||
			_current_test.status == olympus_test_status_getting_user_feedback){
			break;
		}
		else{			
			var this_test_summary =  _current_test.get_summary();	
			if (is_method(_function_to_call_on_test_finish)){
				_function_to_call_on_test_finish(this_test_summary);
			}
			global._olympus_test_manager.execute(_current_test._index+1);
			_interval_between_tests_counter = _interval_between_tests;
		}
	}	
	_interval_between_tests_counter -= 1/room_speed;
	
	if (_current_test.status == olympus_test_status_running){
		if (_current_test._counting_time_out){
			if ((current_time - _current_test._start_time) > _current_test.timeout) {
				_current_test.reject({message:"Async test timed out the threshhold: " + string(_current_test.timeout)}, olympus_error_code.timeout);
			}		
		}
	}	
}	