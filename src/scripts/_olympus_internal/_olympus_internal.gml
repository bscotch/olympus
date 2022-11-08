#region private 
/** 
@desc In the suite summary struct, the "status" key uses the following macros
 */
#macro olympus_summary_status_unstarted "unstarted"
#macro olympus_summary_status_running "running"
#macro olympus_summary_status_completed "completed"
#macro olympus_summary_status_bailed "bailed"
#macro olympus_summary_status_crashed "crashed"
enum olympus_summary_status{
	unstarted = 0,
	running = 1,
	completed = 2,
	bailed = 3,
	crashed = 4
}

/// @desc Internal logging function
/// @param item1
/// @param [item2...]
function _olympus_console_log() {
	if (!variable_global_exists("_olympus_debug_logging_suppressed")){	
		global._olympus_debug_logging_suppressed = false;
	}
	
	if (global._olympus_debug_logging_suppressed) {
		//Do not log
	}
	else
	{
		var echo_item;
		var echo_string="";
		for(echo_item=0;echo_item<argument_count;echo_item++){
			echo_string+=string(argument[echo_item])+" ";
		}
		var final_string = echo_string;
		if (debug_mode) {
			final_string = string_replace_all(final_string, "%", "*");
		}
		show_debug_message(final_string)
	}
}

function _olympus_time_source_destroy_recursive(time_source){
	var _children = time_source_get_children(time_source);
	var _count = array_length(_children);
	for (var i = 0; i < _count; i ++)
	{
	    time_source_destroy(_children[i]);
	}
	time_source_destroy(time_source);
}

/// @desc Merge the new context with the original context of the target_function. In case of conflicts, the new context's value is used
function _olympus_merge_context(target_function, new_context){
	var merged_context = {};
	var source_context = method_get_self(target_function);
	repeat 2 {
		// Null check
		//Feather ignore GM1041 need to support union types
		if ( is_undefined(source_context) || (!is_struct(source_context) && !instance_exists(source_context))){
			source_context = {};			
		}

		// Pick getter and setter based on the source_context type
		var _variable_get_names = variable_struct_get_names;
		var _variable_set_ = variable_struct_set;
		if (!is_struct(source_context) && instance_exists(source_context)){
			_variable_get_names = variable_instance_get_names;
			_variable_set_ = variable_instance_set;
			//Also set the instance id in the context
			//Feather ignore GM1008 id is not a Struct Forbidden Variable
			merged_context.id = source_context;
		}
		
		// Clone the properties to the merged context
		var source_context_keys = _variable_get_names(source_context);
		var source_context_keys_length = array_length(source_context_keys);
		for (var i = 0 ; i < source_context_keys_length; i++){
			var source_context_key = source_context_keys[i];
			var source_context_value = source_context[$ source_context_key];
			merged_context[$ source_context_key] = source_context_value;
		}		
		
		// Run the loop again withe new_context
		source_context = new_context;
	}	
	return merged_context;
}

function _olympus_create_test_controller(){
	if (!instance_exists(_olympus_async_test_controller)){
		var _id = instance_create_depth(0,0, 0, _olympus_async_test_controller);
		
		if (!instance_exists(_id) || _id == -1){
			show_error("Failed to instantiate _olympus_async_test_controller. Please run this function in an object or the room creation event!", true);	
		}
	}
}

///@description Set up the requirement for the hook
///@arg {Function} fn
///@arg {Struct} [context = self]
function _olympus_hook_set_up(fn, context = self) {
	if (!is_method(fn))
		throw("Argument should be a function!");
	else{
		_olympus_create_test_controller();
		var merged_context = _olympus_merge_context(fn, context);		
		var binded_function = method(merged_context, fn);
		return binded_function;
	}	
}

function _olympus_get_resolve_function_handle(){
	var callback_struct_variable_name = "_resolution_callback_name";
	return _olympus_get_callback_handle(callback_struct_variable_name);
}

function _olympus_get_reject_function_handle(){
	var callback_struct_variable_name = "_rejection_callback_name";
	return _olympus_get_callback_handle(callback_struct_variable_name);
}

function _olympus_get_callback_handle(callback_struct_variable_name){
	var callback_handle = function(){_olympus_console_log("The suite already completed")};
	var current_suite = global._olympus_suite_manager.current_suite;
	if (is_struct(current_suite) && current_suite.is_running()) {
		var current_test = current_suite.get_current_test();
		/// Feather ignore GM1028 Need to assert Mixed type or allow arbitary key
		var callback_name = current_test[$ callback_struct_variable_name];
		var mediator_id = current_test._mediator_id;	
		/// Feather ignore GM1041 Need to assert variable type when the user knows it
		var callback_handle = (mediator_id == id) ? variable_instance_get(id, callback_name) : function(){_olympus_console_log("This mediator already timed out:", object_get_name(object_index), id)};
	}
	return callback_handle;
}

#endregion

///@arg {string} error_message
///@arg {enum.olympus_error_code} error_code
///@arg {struct} [info] Any additional information that is packaged in a struct
///@arg {Array<String>} [stacktrace]
function _Olympus_Test_Error(error_message, error_code, info = undefined, stacktrace = undefined) constructor{
	message = error_message;
	code  = error_code;	
	if (!is_undefined(info)){
		variable_struct_set(self, "info", info);
	}
		
	if (!is_undefined(stacktrace)){
		variable_struct_set(self, "stacktrace", stacktrace);
	}	
}

function _Olympus_Suite_Manager() constructor {
	_suites = [];
	current_suite = undefined;
	
	/// @arg {Struct._Olympus_Suite} suite
	add_suite = function(suite){
		array_push(_suites, suite);
	}	
	_process_queue = function(){
		if (array_length(_suites) > 0){		
			current_suite = _suites[0];
			var suite_status = current_suite.status();
			switch (suite_status) {
				case olympus_summary_status_crashed:				
				case olympus_summary_status_unstarted:
					current_suite.queue_test();
					break;
				case olympus_summary_status_running:
					//do nothing
					break;
				case olympus_summary_status_bailed:
				case olympus_summary_status_completed:
					array_delete(_suites, 0, 1);
					delete current_suite._my_summary_manager_ref;
					delete current_suite;
					break;
			}
		}
		else{
			current_suite = undefined;
		}
	}
	_queue_processing_time_source = time_source_create(time_source_global, 1, time_source_units_frames, _process_queue, [], -1, time_source_expire_after);
	time_source_start(_queue_processing_time_source);
	
	destroy = function(){
		time_source_destroy(_queue_processing_time_source);
	}
}
global._olympus_suite_manager = new _Olympus_Suite_Manager();

#macro olympus_test_interval_millis_default 0.01 

function _Olympus_Suite_Options() constructor{
	abandon_unfinished_record = false;
	skip_user_feedback_tests = false;
	suppress_debug_logging = false;
	test_interval_millis = olympus_test_interval_millis_default;
	global_resolution_callback_name = "_olympus_test_resolution_callback";
	global_rejection_callback_name = "_olympus_test_rejection_callback";
	bail_on_fail_or_crash = false;
	context = undefined;
	global_timeout_millis = 60000;
	allow_uncaught = false;
	ignore_if_completed = false;	
	forbid_only = false;
	forbid_skip = false;
	parent_timeout_time_source = time_source_global;
	parent_test_interval_time_source = time_source_global;
	function_to_call_on_test_start = undefined;
	function_to_call_on_test_finish = undefined;
	exit_on_completion= false;
	bypass_only = false;
}

///@description Struct used to manage and execute all registered tests
function _Olympus_Suite(suite_name, function_to_add_tests_and_hooks, options): _Olympus_Suite_Options() constructor {
	_tests = [];
	_startTime=undefined;
	_function_to_call_on_suite_finish = undefined; // User-provided function to execute when all tests have concluded.
	_function_to_call_on_suite_start = undefined; // User-provided function to execute before all tests start.	
	_current_test_index = -1;	
	_completion_time = undefined;
	_suite_name = "unnamed_suite";
	_dependency_chain_last_test_name = "";
	_dependency_chain_active = false;
	_my_summary_manager_ref = noone;	
	_timeout_time_source = undefined;
	_test_interval_time_source = undefined;
	_my_parent = undefined;
	default_options = new _Olympus_Suite_Options();

	///@arg {Struct._Olympus_Suite_Options} options
	_load_options = function(options){
		if (is_struct(options)){
			var options_keys = variable_struct_get_names(options);
			var options_keys_length = array_length(options_keys);
			for (var i = 0 ; i < options_keys_length; i++){
				var options_key = options_keys[i];
				var options_value = options[$options_key];
				variable_struct_set(self, options_key, options_value);
				self.default_options[$options_key] = options_value;
			}
		}
	}

	///@param {String} suite_name The name of the suite and the summary file
	///@param {function} function_to_add_tests_and_hooks
	///@param {Struct} options {abandon_unfinished_record:bool, skip_user_feedback_tests:bool, test_interval_millis: number, suppress_debug_logging:bool, global_resolution_callback_name: string, global_rejection_callback_name: string}
	_set_up_with_options = function(suite_name, function_to_add_tests_and_hooks, options){
		var olympus_suite_parent = options[$ "olympus_suite_parent"];
		if (is_struct(olympus_suite_parent)) {
			_my_parent = olympus_suite_parent;
			_load_options(_my_parent.default_options);
		}
		_load_options(options);		

		context = _olympus_merge_context(function_to_add_tests_and_hooks, context);		
		context[$ "_olympus_suite_ref"] = self;
		function_to_add_tests_and_hooks = method(context, function_to_add_tests_and_hooks);
		function_to_add_tests_and_hooks();
			
		_check_for_only_and_skipped_tests();				

		var test_interval_seconds = olympus_test_interval_millis_default/1000;
		_test_interval_time_source = time_source_create(parent_test_interval_time_source, test_interval_seconds, time_source_units_seconds, _callback_between_test_intervals, [], 1, time_source_expire_after);		

		_suite_name = suite_name;
		_my_summary_manager_ref = new _Olympus_Summary_Manager(_suite_name, self);
		
		_olympus_create_test_controller();
		
		date_set_timezone(timezone_utc);
		_startTime = current_time;


		if (abandon_unfinished_record || allow_uncaught) {
			_my_summary_manager_ref.initialize_summary();
		}
		else{			
			_my_summary_manager_ref.load_previous_summary(ignore_if_completed);			
		}				
		
		global._olympus_debug_logging_suppressed = suppress_debug_logging;
		
		if (!allow_uncaught){
			exception_unhandled_handler(function(ex){
				//Feather ignore GM1041 need to support type narrowing of enums
				var olympus_error = new _Olympus_Test_Error("Unhandled exception", olympus_error_code.unhandled_exception, ex);
				_my_summary_manager_ref.update_tests_crashed(olympus_error);
				_my_summary_manager_ref.write_summary_to_file();
				show_message(ex);
			})
		}		 
		
		show_debug_overlay(true);
		global._olympus_suite_manager.add_suite(self);
	}

	_callback_between_test_intervals = function(){
		while (is_running()){
			var _current_test = get_current_test();
			var _current_test_status = _current_test.status;
			if (_current_test_status == olympus_test_status_unstarted){					
				var this_test_summary = _current_test.get_summary();
				if (is_method(function_to_call_on_test_start)){
					function_to_call_on_test_start(this_test_summary);
				}
				if (bail_on_fail_or_crash && _my_summary_manager_ref.has_failure_or_crash()){
					_current_test.disabled = true;
				}			
				_olympus_console_log("Running test #", _current_test._index);				
				_current_test.run();
			}

			if (_current_test._is_running()){
				// An async test is running. Check for status change as soon as possible
				time_source_reconfigure(_test_interval_time_source, olympus_test_interval_millis_default/1000, time_source_units_seconds, _callback_between_test_intervals, [], 1, time_source_expire_after);
				time_source_start(_test_interval_time_source);				
				return;
			}
			else{
				// Test is completed
				var this_test_summary =  _current_test.get_summary();	
				if (is_method(function_to_call_on_test_finish)){
					function_to_call_on_test_finish(this_test_summary);
				}
				queue_test(_current_test._index+1);
				if (test_interval_millis != olympus_test_interval_millis_default){										
					time_source_reconfigure(_test_interval_time_source, test_interval_millis/1000, time_source_units_seconds, _callback_between_test_intervals, [], 1, time_source_expire_after);
					time_source_start(_test_interval_time_source);
					return;
				}
				else{
					continue;
				}
			}
		}
	}

	///@description Queue the n-th test struct.
	///@param {real} [test_index=undefined]
	queue_test = function (test_index=undefined) {
		if (is_undefined(test_index)){
			// We are starting from the beginning
			if (is_method(_function_to_call_on_suite_start)){
				_function_to_call_on_suite_start(_my_summary_manager_ref.get_summary());
			}
			test_index = _my_summary_manager_ref.get_beginning_test_index();
			time_source_start(_test_interval_time_source);
		}		

		if(test_index == array_length(_tests)){
			// Then we have completed all tests
			var end_status = olympus_summary_status_completed;
			if (bail_on_fail_or_crash && _my_summary_manager_ref.has_failure_or_crash()){
				end_status = olympus_summary_status_bailed;
			}
			_conclude_tests(end_status);
		}
		else{
			_current_test_index = test_index;
		}		
	}
	
	get_global_resolution_callback_name = function(){
		return global_resolution_callback_name;
	}
	
	get_global_rejection_callback_name = function(){
		return global_rejection_callback_name;
	}

	_check_for_only_and_skipped_tests = function(){
		var should_remove_non_only_tests = false;
		for (var i = 0; i < array_length(_tests); i++){
			var this_test = _tests[i];
			if (this_test._only == true) {
				if (forbid_only){
					#macro _olympus_suite_execution_error_forbid_only "The suite forbids using the olympus_test_options_only option."
					throw({message: _olympus_suite_execution_error_forbid_only, test_name: this_test._name});
				}
				else{
					should_remove_non_only_tests = true;					
				}
			}			
			
			if (forbid_skip){
				if (this_test.disabled == true) {
					#macro _olympus_suite_execution_error_forbid_skip "The suite forbids skipping test."
					throw({message: _olympus_suite_execution_error_forbid_skip, test_name: this_test._name});
				}				
			}
		}
		if (bypass_only){
			_olympus_console_log("bypass_only is enabled. Will not remove non-only tests.");
			should_remove_non_only_tests = false;
		}	
		
		if (should_remove_non_only_tests){
			for (var i = array_length(_tests) -1; i >= 0; i--){
				var this_test = _tests[i];
				if (this_test._only != true) {
					array_delete(_tests, i, 1);	
				}
			}
		
			//Re-index the suite after deleting a bunch of tests
			for (var i = array_length(_tests) -1; i >= 0; i--){
				var this_test = _tests[i];
				this_test._index = i;
			}		
		}
	}

	_clean_up = function() {
		time_source_stop(_test_interval_time_source);
		_olympus_time_source_destroy_recursive(_test_interval_time_source);
		show_debug_overlay(false);		
	}	
	
	///@description Once all tests have passed, failed, or timed out, call this function.
	_conclude_tests = function(status) {
		//Feather ignore GM1010 need to be able to assert variable types
		_completion_time = current_time - _startTime;
		_my_summary_manager_ref.complete(status);
		if (!allow_uncaught){
			//Feather ignore GM1041 Need to update the function signature of exception_unhandled_handler()
			exception_unhandled_handler(undefined);	//Restore the exception handler to default state.
		}
		if (is_method(_function_to_call_on_suite_finish)){
			_function_to_call_on_suite_finish(_my_summary_manager_ref.get_summary());
		}
		_clean_up();
		if (exit_on_completion){
			game_end();
		}
	}
	
	/// @description Adds a test to this manager and return the test index
	/// @param {Struct._Olympus_Test} test
	add_test = function(test){
		var test_name = test._name;
		
		if (get_test_by_name(test_name) != noone){
			throw({message: "This test name was already added: " + test_name, name: test_name});
		}
		else{
			array_push(_tests, test);
			return array_length(_tests)-1;
		}
	}
	
	get_test_by_name = function(name){
		for (var i = 0; i < array_length(_tests); i ++){
			var this_test = _tests[i];
			if (this_test._name == name){
				return this_test;
			}
		}
		return noone;
	}
	
	///@description Gets the current test unit that is being tested
	get_current_test = function(){
		return _tests[_current_test_index];
	}
	
	dependency_chain_begin = function(){
		_dependency_chain_active = true;
	} 

	dependency_chain_end = function(){
		_dependency_chain_active = false;
		_dependency_chain_last_test_name = "";
	}
	
	is_running = function(){
		return (_my_summary_manager_ref.status() == olympus_summary_status_running);
	}
	
	status = function(){
		return _my_summary_manager_ref.status();
	}

	_set_up_with_options(suite_name, function_to_add_tests_and_hooks, options)
}

///@description Struct used to hold the registered test data for later execution
///@param {String} name
///@param {Function} fn
///@param {Function} [resolution_fn] The function to be executed when the async function resolves
///@param {String} [prompt] The prompt to instruct the tester
///@param {struct.Olympus_Test_Options} [options] 
function _Olympus_Test(name, fn, resolution_fn = undefined, prompt = undefined, options = {}) constructor {	
	var resolution_callback_name = options[$"resolution_callback_name"];
	var rejection_callback_name = options[$"rejection_callback_name"];
	var context = options[$"context"];
	var resolution_context = options[$"resolution_context"];
	var timeout_millis = options [$"timeout_millis"];
	var only = options [$ "only"];
	var importance = options [$ "importance"];

	_name = name;
	_test_fn = fn;
	_test_fn_context = is_struct(context) ? context : undefined;
	_only = only;
	my_suite_ref = options[$ "_olympus_suite_ref"];
	var test_index = my_suite_ref.add_test(self);
	_index = test_index;
	disabled = false;
	_counting_time_out = true;
	status = olympus_test_status_unstarted;
	_err = undefined;
	_resolution_fn = resolution_fn;
	_is_async = is_method(_resolution_fn);	
	_resolution_fn_context = is_struct(resolution_context) ? resolution_context : undefined;
	_resolution_callback_name = is_string(resolution_callback_name) ? resolution_callback_name : "";
	_rejection_callback_name = is_string(rejection_callback_name) ?  rejection_callback_name : "";
	timeout = is_numeric(timeout_millis)? timeout_millis : my_suite_ref.global_timeout_millis;
	_start_time = current_time;
	_completion_time = undefined;
	_user_feedback_prompt = prompt;	
	_user_feedback_required = is_string(prompt);
	_mediator_id = -1;
	_dependencies = [];
	_timeout_time_source = undefined;
	_importance = is_numeric(importance) ? importance : olympus_test_importance.normal;
	
	_get_non_passing_dependency_names = function(){
		var non_passing_dependency_names = [];
		//Feather ignore GM1041 Need to detect variables from enclosing context
		for (var i = 0; i < array_length(_dependencies); i++){
			var dependency_test = _dependencies[i];
			if (dependency_test.status != olympus_test_status_passed){
				array_push(non_passing_dependency_names, dependency_test._name);
			}
		}
		return non_passing_dependency_names;
	}
	
	///@desc Ensure the test callback and resolution callback have access to their contexts
	_bind_callback_context = function(){		

		var merged_context = _olympus_merge_context(_test_fn, _test_fn_context)
		_test_fn = method(merged_context, _test_fn);
						
		if (_is_async && is_method(_resolution_fn)){
			var merged_context = _olympus_merge_context(_resolution_fn, _resolution_fn_context);
			_resolution_fn = method(merged_context, _resolution_fn);
		}						
	}
	
	_set_timeout = function(milliseconds){
		timeout = milliseconds;
	}

	_run_resolution_fn = function(_param_array){
		_resolution_fn(_param_array);					
		if (_user_feedback_required){
			status = olympus_test_status_getting_user_feedback;
			_set_completion_time(); //Stop incremention the completion time as we don't know how long the user will take to complete the test
			var user_feedback_handle = _get_user_feedback_async();
			with _olympus_async_test_controller{
				_current_test = other;
				_user_feedback_handle = user_feedback_handle;
			}							
		}
		else{
			resolve();
		}		
	}

	_create_resolution_callback = function(){	
		return method(self, function(){
			//Feather ignore GM1013 Need to detect variables from enclosing context
			if (status == olympus_test_status_running){
				var _param_array = [];
				for (var i = 0; i < argument_count; i ++){
					_param_array[i] = argument[i];
				}						
				
				if (my_suite_ref.allow_uncaught){
					_run_resolution_fn(_param_array);
				}
				else{
					try{
						_run_resolution_fn(_param_array);
					}
					catch(err){					
						reject(err, olympus_error_code.failed_resolution);
					}					
				}
			}
			else{
				_olympus_console_log("Resolution was already attempted for:", _name);
			}
		});
	}

	///@desc Displays the user feedback prompt, and returns the async handle
	_get_user_feedback_async = function(){
		//Feather ignore GM1010 need to be able to assert types
		var prompt =  _user_feedback_prompt  + " (Type 'Pass' and hit 'OK' to pass, or enter your own message and hit 'OK' to fail the test. 'Cancel' will always fail the test.)"
		var user_feedback_handle = get_string_async(prompt, _olympus_user_feedback_confirm_message);
		return user_feedback_handle;
	}

	_set_up = function(){
		_timeout_time_source = time_source_create(my_suite_ref.parent_timeout_time_source, timeout/1000, time_source_units_seconds, reject, [{message:"Test timed out the threshhold: " + string(timeout)}, olympus_error_code.timeout], 1, time_source_expire_after);
		time_source_start(_timeout_time_source);
		status = olympus_test_status_running;
		_start_time = current_time;
		my_suite_ref._my_summary_manager_ref.update_tests(get_summary());
		my_suite_ref._my_summary_manager_ref.update_progress(_index, _name);
		my_suite_ref._my_summary_manager_ref.write_summary_to_file();			
	}
	
	_is_running = function(){
		return status == olympus_test_status_running ||
				status == olympus_test_status_getting_user_feedback
	}

	/// @desc return a copy of the individual test's summary
	get_summary = function(){
		var individual_test_summary = {
			index: _index,
			name: _name,
			millis: _completion_time,
			status: status,
			importance: _importance
		}
		if (is_struct(_err)){
			individual_test_summary[$"err"] = _err;
		}
		return individual_test_summary;
	}

	_tear_down = function() {
		// After we are done testing 
		if (is_undefined(_completion_time)){
			_set_completion_time();			
			_olympus_time_source_destroy_recursive(_timeout_time_source);			
		}								
		my_suite_ref._my_summary_manager_ref.update_tests(get_summary());		
		my_suite_ref._my_summary_manager_ref.update_progress(_index, _name);
		my_suite_ref._my_summary_manager_ref.update_tallies();
		my_suite_ref._my_summary_manager_ref.write_summary_to_file();
	}

	_update_err_for_disabling_reasons = function(){
		if (disabled){
			//Feather ignore GM1041 need to support type narrowing of enums
			_err = new _Olympus_Test_Error("Skipped by xolympus_add_*", olympus_error_code.skip_with_x);
		}		
		else if (my_suite_ref.bail_on_fail_or_crash && my_suite_ref._my_summary_manager_ref.has_failure_or_crash()){
			//Feather ignore GM1041 need to support type narrowing of enums
			_err = new _Olympus_Test_Error("Skipped because of bail", olympus_error_code.skip_with_bail);
		}
		else if	(_user_feedback_required && my_suite_ref.skip_user_feedback_tests){
			//Feather ignore GM1041 need to support type narrowing of enums
			_err = new _Olympus_Test_Error("Skipped because user feedback is suppressed", olympus_error_code.skip_with_suppress);
		}
		else if (array_length(_get_non_passing_dependency_names()) > 0){
			//Feather ignore GM1041 need to support type narrowing of enums
			_err = new _Olympus_Test_Error("Skipped because dependency did not pass", olympus_error_code.skip_with_dependency, _get_non_passing_dependency_names());
		}		
	}	

	_run_test_fn = function(){
		if(_is_async){
			_attach_callback_to_mediator();
		}
		else{
			_test_fn();
			//Feather ignore GM1010 Need to detect variables from enclosing context or this is a bug		
			if  ((current_time - _start_time) > timeout) {				
				//Feather ignore GM1041 need to support type narrowing of enums
				reject( new _Olympus_Test_Error("Sync Test Exceeded Timeout: " + string(timeout), olympus_error_code.timeout), olympus_error_code.timeout);
			}
			else{
				resolve();
			}
		}			
	}

	///@description Run test
	run = function (){
		_set_up();
		_log_status();
		_bind_callback_context();
		_update_err_for_disabling_reasons();

		if (is_struct(_err)){
			_skip();			
		}
		else{
			if (my_suite_ref.allow_uncaught){
					_run_test_fn()			
			}
			else{
				try {
					_run_test_fn();
				} catch (err){
					var code = olympus_error_code.failed_sync;
					if (_is_async){
						code = olympus_error_code.failed_async_mediator_spawning;
					}
					//Feather ignore GM1041 need to support type narrowing of enums
					reject(err, code);
				}
			}
		}
	}		

	_attach_resolution_to_mediator = function(mediator_id, resolution_callback){
		if (_resolution_callback_name == ""){
			_resolution_callback_name = my_suite_ref.get_global_resolution_callback_name();
		}
		variable_instance_set(mediator_id, _resolution_callback_name, resolution_callback);
	}

	_attach_rejection_to_mediator = function(mediator_id){
		if (_rejection_callback_name == ""){
			_rejection_callback_name = my_suite_ref.get_global_rejection_callback_name();
		}
		variable_instance_set(mediator_id, _rejection_callback_name, reject);			
	}

	_attach_callback_to_mediator = function(){
		var resolution_callback = _create_resolution_callback();
		//_test_fn is the mediator spawning logic in async tests
		var mediator_id = _test_fn(resolution_callback, reject);
		if (!is_undefined(mediator_id)){
			_mediator_id = mediator_id;
			_attach_resolution_to_mediator(mediator_id, resolution_callback);
			_attach_rejection_to_mediator(mediator_id);			
		}
		else{
			//The user should have set the callback through with statement, 
			//but if they also specified the override through options, we need to warn them
			if (_resolution_callback_name != "" || _rejection_callback_name != ""){
				show_error("You did not return a mediator instance but specified a callback name: " + _resolution_callback_name + " " + _rejection_callback_name, true);
			}
		}
	}

	_skip = function(){
		status = olympus_test_status_skipped;
		_done();
	}

	_set_completion_time = function(){
		//Feather ignore GM1010 Need to detect variables from enclosing context
		time_source_stop(_timeout_time_source);
		var test_duration = current_time - _start_time;
		_completion_time = test_duration;
		_counting_time_out = false;
	}

	/// @desc By default, log the result as failure. If _allow_uncaught, throw the error instead
	/// @param {Struct.Exception} err Error that caused the test to fail
	/// @param {enum.olympus_error_code} [code = olympus_error_code.user_defined] olympus_error_code enums
	reject = function(err, code = olympus_error_code.user_defined){
			if (my_suite_ref.allow_uncaught){
				throw(err);
			}
			else{
				status = olympus_test_status_failed;			
				//Feather ignore GM1041 need to support type narrowing of enums
				var olympus_err = _convert_user_error_to_olympus_error(err, code);
				_olympus_console_log(olympus_err.message);
				_err = olympus_err;
				_done();
			}
	}
	
	/// @param {Struct.Exception | Mixed} err Error that caused the test to fail
	/// @param {enum.olympus_error_code} code olympus_error_code enums
	_convert_user_error_to_olympus_error = function(err, code) {
		if (is_struct(err)){
			err = json_parse(json_stringify(err));
			var message = ""; 
			var stacktrace = undefined;
			if (variable_struct_exists(err, "message")) {
				message =  err[$"message"];
				variable_struct_remove(err, "message");
			}
			if (variable_struct_exists(err, "stacktrace")) {
				stacktrace =  err[$"stacktrace"];
				variable_struct_remove(err, "stacktrace");
			}
			if (variable_struct_names_count(err) <= 0){
				err = undefined;
			}
			return  new _Olympus_Test_Error(message, code, err, stacktrace);
		}
		else{
			return new _Olympus_Test_Error("User defined non-struct error", code, err);
		}
	}	

	resolve = function(){
		status = olympus_test_status_passed;
		_done();
	}

	/// @description Tears down, logs the result, and starts the next test
	_done = 	function(){
		_log_status();
		_olympus_console_log("\n");
		_tear_down();		
	}
	
	///@description Logs the status for the test to the console
	_log_status = function(){		
		//Feather ignore GM1010 Need to detect variables from enclosing context
		_olympus_console_log("[" + status + "] " + _name);
	}

	#region registering dependencies
		var dependency_names = [];
		var dependency_names_raw = options[$"dependency_names"];
		if (is_string(dependency_names_raw)){
			dependency_names = [dependency_names_raw];
		}
		else if (is_array(dependency_names_raw)){
			dependency_names = dependency_names_raw;
		}
		if (my_suite_ref._dependency_chain_active) {
			var last_dependency_name = my_suite_ref._dependency_chain_last_test_name;
			if (last_dependency_name != ""){
				array_push(dependency_names, last_dependency_name);
			}
		}

		array_sort(dependency_names, true);
		var previous_dependency_name = "";
		for (var i = 0; i < array_length(dependency_names); i++){
			var dependency_name = dependency_names[i];
			if (previous_dependency_name != dependency_name){
				var dependency_test = my_suite_ref.get_test_by_name(dependency_name);
				if (dependency_test == noone){
					throw({message: "The dependent test name " + dependency_name + " has not been added yet!", test_name: dependency_name});
				}
				else if (dependency_test == self){
					_olympus_console_log("Will not register self as dependencies");
				}
				else {
					array_push(_dependencies, dependency_test);
				}				
				previous_dependency_name = dependency_name;				
			}
			else{
				var warning_message = "This dependency name is already registered: " + dependency_name;
				_olympus_console_log(warning_message);
			}
		}
		if (my_suite_ref._dependency_chain_active){
			my_suite_ref._dependency_chain_last_test_name = _name;
		}		
	#endregion
}

///@description Struct used to hold the test summary for resuming tests and export
function _Olympus_Summary_Manager(suite_name, _my_suite_ref) constructor{
	//TODO: The reference should be managed by the meta controller when it is implemented.
	static _config = { 
		runtime: {
			version: GM_runtime_version,
			optimized : code_is_compiled()
		},
		os: {
			identifier: os_type
		},
		project:{
			name: game_project_name,
			config: os_get_config(),
			version: GM_version,
			debug: debug_mode 
		},
	};

	_summary = {};
	my_suite_ref = _my_suite_ref;
	
	///@description Initialize a new summary
	initialize_summary = function() {
		_purge_record();		
		_summary = {
			config: _config,
			tallies: {
				total:  array_length(my_suite_ref._tests),
				failed: -1,
				skipped: -1,
				passed: -1,
				crashed: -1
			},
			tests: [],
			progress: {
				last_test_index: 0,
				last_test_name: "N/A"
			},
			status: olympus_summary_status_unstarted,
			name: _get_safe_name(my_suite_ref._suite_name)
		}
		_initialize_tests();
	}
	
	_initialize_tests = function(){
		var tests = my_suite_ref._tests;
		for (var i = 0; i < array_length(tests); i++){
			update_tests(tests[i].get_summary());
		}
	}	
	
	///@desc Sets the name of the summary with kabob casing
	///@arg {String} name
	_set_name = function(name){
		_summary.name = _get_safe_name(name);
	}
	
	///@desc Convert to safe file name
	///@arg {String} file_name_raw
	_get_safe_name = function(file_name_raw){
		var file_name_safe = string_lower(file_name_raw);
		file_name_safe = string_replace_all(file_name_safe, " ", "_");
		file_name_safe = string_replace_all(file_name_safe, "/", "_");
		file_name_safe = string_replace_all(file_name_safe, ":", "_");
		file_name_safe = string_replace_all(file_name_safe, "\\", "_");
		file_name_safe = string_replace_all(file_name_safe, ":", "_");
		file_name_safe = string_replace_all(file_name_safe, "*", "_");
		file_name_safe = string_replace_all(file_name_safe, "?", "_");
		file_name_safe = string_replace_all(file_name_safe, "\"", "_");
		file_name_safe = string_replace_all(file_name_safe, "<", "_");
		file_name_safe = string_replace_all(file_name_safe, ">", "_");
		file_name_safe = string_replace_all(file_name_safe, "|", "_");		
		return file_name_safe;
	}

	_get_summary_file_name = function(){
		return "Olympus_records/internal/" + string(_summary.name) + ".raw.olympus.json"
	}
	
	_get_prettified_summary_file_name = function(){
		return "Olympus_records/" + string(_summary.name) + ".olympus.json"
	}

	///@desc Deletes the existing summary file and initialize a new one
	_purge_record = function() {
		if (file_exists(_get_summary_file_name())){
			file_delete(_get_summary_file_name());
		}
	}	
	
	///@description Reads the summary data from a json file
	_load_summary_from_json_file = function() {
		var jsonstr;
		var f = file_text_open_read(_get_summary_file_name()),
			jsonstr = "";
		while (!file_text_eof(f)) {
			jsonstr += file_text_read_string(f);
			file_text_readln(f);
		}
		file_text_close(f);
		return json_parse(jsonstr);
	}
	
	///@description Check whether the summary data is outdated from the current setting
	_summary_data_is_outdated = function(summary){
		return summary.config.project.config  != os_get_config()
		||summary.config.os.identifier != os_type
		||summary.config.project.name != game_project_name
		|| summary.config.project.version != GM_version
		|| summary.config.project.debug != debug_mode
		|| summary.tallies.total != array_length(my_suite_ref._tests)
		|| summary.config.runtime.version != GM_runtime_version
		|| summary.config.runtime.optimized != code_is_compiled()
	}
	
	///@description Returns the unit index to begin the test suite with
	get_beginning_test_index = function(){
		_olympus_console_log("Suite name:", _summary.name);
		var beginning_test_index = 0; 
		if (_summary.status == olympus_summary_status_crashed) {
			_summary.status = olympus_summary_status_running;
			beginning_test_index = _summary.progress.last_test_index;
			_olympus_console_log("We are resuming a suite. Skipping the last test because it probably caused a crash: ", beginning_test_index);
			beginning_test_index ++;
		}
		else if (_summary.status == olympus_summary_status_completed || _summary.status == olympus_summary_status_bailed){
			_olympus_console_log("The suite was already completed or bailed!");
			beginning_test_index = _summary.tallies.total;
		}		
		else{
			_olympus_console_log("We are starting from the beginning of the suite!");
			_summary.status = olympus_summary_status_running;
		}
		return beginning_test_index;
	}
	
	///@desc Load the previous summary
	load_previous_summary = function(ignore_if_completed){
		if (file_exists(_get_summary_file_name())){
			var previous_summary = _load_summary_from_json_file();			
			_olympus_console_log("Successfully loaded summary.");			
			if (_summary_data_is_outdated(previous_summary)){
				_olympus_console_log("Outdated summary. Reinitializing.")
				initialize_summary();
			}
			else{
				_summary = previous_summary;
				if (_summary.status == olympus_summary_status_running){	
					_olympus_console_log("The summary is resumed from an interrupted run. Need to ensure that the last test is recorded as a crash.");
					_summary.status = olympus_summary_status_crashed;
					var crashed_test = _summary.tests[_summary.progress.last_test_index];
					if  (crashed_test[$ "status"] != olympus_test_status_crashed) {
						_olympus_console_log("Last run had a crash with uncaught exception.");
						//Feather ignore GM1041 need to support type narrowing of enums
						var err = new _Olympus_Test_Error("Uncaught crash", olympus_error_code.uncaught_crash);
						update_tests_crashed(err);
					}
					else{
						_olympus_console_log("Last run had a crash and the exception was logged.");
					}			
				}
				else if (_summary.status == olympus_summary_status_unstarted){
					_olympus_console_log("The summary never started. Restarting fresh.");
					initialize_summary();
				}
				else{
					_olympus_console_log("Loaded a summary that was already completed.");
					if (ignore_if_completed){
						_olympus_console_log("Skipping rerunning the suite.");
					}
					else{
						_olympus_console_log("Rerunning the suite");
						initialize_summary();				
					}
				}
			}
		}
		else{
			_olympus_console_log("No record. Start new.");
			initialize_summary();			
		}
	}
	
	///@desc Convert summary to a json string and write to file
	write_summary_to_file = function(){
		if (!my_suite_ref.allow_uncaught){		
			var summary = argument_count > 0 ? argument[0] : _summary;
			var file_name = argument_count > 1 ? argument[1] : _get_summary_file_name();	
			var output_string = json_stringify(summary);
			var fh = file_text_open_write(file_name);
			file_text_write_string(fh,output_string);
			file_text_close(fh);

			if (os_type == os_switch){
				//Feather ignore GM1013 Need to support console specific functions
				switch_save_data_commit();
			}
		}
	}
	
	///@desc Update the summary's tallies section
	update_tallies = function(){
		var failed_count = 0;
		var passed_count = 0; 
		var skipped_count = 0;
		var crashed_count = 0;
		for (var i = 0; i < array_length(_summary.tests); i++){
			switch (_summary.tests[i].status){
				case olympus_test_status_passed:
					passed_count++;
					break;
				case olympus_test_status_failed:
					failed_count ++;
					break;
				case olympus_test_status_skipped:
					skipped_count++;
					break;
				case olympus_test_status_crashed:
					crashed_count++;
					break;
			}
		}		
		_summary.tallies.failed = failed_count;
		_summary.tallies.passed = passed_count;
		_summary.tallies.skipped = skipped_count;
		_summary.tallies.crashed = crashed_count;
	}
	
	///@desc Update the summary's progress section
	///@arg {Real} test_index
	///@arg {String} name
	update_progress = function(test_index, name){
		_summary.progress.last_test_index = test_index;
		_summary.progress.last_test_name = name;
	}
	
	///@desc Update the summary's tests section
	///@arg {Struct} individual_test_summary
	update_tests = function(individual_test_summary){		
		_summary.tests[individual_test_summary.index] = individual_test_summary;
	}
	
	///@desc Update the summary's units crashed section
	///@arg {struct} olympus_error
	update_tests_crashed = function(olympus_error){		
		var crashed_test_summary = my_suite_ref._tests[_summary.progress.last_test_index].get_summary();
		crashed_test_summary.status = olympus_test_status_crashed;
		variable_struct_remove(crashed_test_summary, "millis");
		crashed_test_summary[$"err"] = olympus_error;
		update_tests(crashed_test_summary);
	}
	
	///@desc Return the copy of the summary struct
	get_summary = function(){
		return  json_parse(json_stringify(_summary));
	}
	
	///@desc Return whether there are tests that failed or crashed
	has_failure_or_crash = function(){
		return (_summary.tallies.failed > 0 || _summary.tallies.crashed >0);				
	}
	
	get_failed_or_crashed_tests = function(){
		var failed_or_crashed_tests = array_create(0);
		for (var i = 0; i < array_length(_summary.tests); i++){
			var a_test = _summary.tests[i];
			switch (a_test.status){
				case olympus_test_status_failed:
				case olympus_test_status_crashed:
					array_push(failed_or_crashed_tests, a_test);
					break;
				default:
					break;
			}
		}
		return failed_or_crashed_tests;
	}

	_get_prettified_summary = function(){
		variable_struct_remove(_summary, "progress");
		variable_struct_remove(_summary, "config");
		return self._summary;
	}

	///@desc Logs the suite completion state
	complete = function(status){
		_summary.status = status;
		write_summary_to_file();
		
		var prettified_summary =  _get_prettified_summary();
		var summary_file_name = _get_prettified_summary_file_name();
		write_summary_to_file(prettified_summary, summary_file_name);	
		
		_olympus_console_log("-------------------------");
		_olympus_console_log("total: " +		string(_summary.tallies.total));
		_olympus_console_log(olympus_test_status_passed + ": " +		string(_summary.tallies.passed));
		_olympus_console_log(olympus_test_status_failed + ": " +		string(_summary.tallies.failed)); 
		_olympus_console_log(olympus_test_status_skipped + ": " + +	string(_summary.tallies.skipped));
		_olympus_console_log(olympus_test_status_crashed + ": " + +	string(_summary.tallies.crashed));
		_olympus_console_log("Record written to file as", summary_file_name);
		_olympus_console_log("-------------------------");				
	}
	
	status = function(){
		return _summary.status;
	}
		
	_set_name(suite_name);
}

