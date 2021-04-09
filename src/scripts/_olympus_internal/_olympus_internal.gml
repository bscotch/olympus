#region private 
/** 
@desc In the suite summary struct, the "status" key uses the following macros
 */
#macro olympus_summary_status_unstarted "unstarted"
#macro olympus_summary_status_running "running"
#macro olympus_summary_status_completed "completed"
#macro olympus_summary_status_bailed "bailed"
enum olympus_summary_status{
	unstarted = 0,
	running = 1,
	completed = 2,
	bailed = 3
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
///@arg {Struct} [context]
function _olympus_hook_set_up(fn, context) {
	_olympus_forbid_adding_outside_suite();
	_olympus_forbid_change_during_testing();
	if (!is_method(fn))
		throw("Argument should be a function!");
	else{
		_olympus_create_test_controller();
		var binded_function = method(context, fn);
		return binded_function
	}	
}

#macro _olympus_forbid_change_during_testing_err "Cannot make changes while the test suite is running!"
function _olympus_forbid_change_during_testing(){
	if (variable_global_exists("_olympus_test_manager") && is_struct(global._olympus_test_manager) && global._olympus_test_manager[$"_startTime"]){
		throw(_olympus_forbid_change_during_testing_err);
	}	
}

#macro _olympus_forbid_adding_outside_suite_err "Cannot add tests or hooks outside of the execution of olympus_run()!"
function _olympus_forbid_adding_outside_suite(){
	if (!variable_global_exists("_olympus_test_manager") || !is_struct(global._olympus_test_manager)){
		throw(_olympus_forbid_adding_outside_suite_err);
	}	
}

function _olympus_add_hook_before_each_test_start(fn, context){
	var function_with_setup = _olympus_hook_set_up(fn, context);
	_olympus_async_test_controller._function_to_call_on_test_start = function_with_setup;		
}

function _olympus_add_hook_after_each_test_finish(fn, context){
	var function_with_setup = _olympus_hook_set_up(fn, context)
	_olympus_async_test_controller._function_to_call_on_test_finish = function_with_setup;		
}

function _olympus_add_hook_before_suite_start(fn, context){
	var function_with_setup = _olympus_hook_set_up(fn, context)
	global._olympus_test_manager._function_to_call_on_suite_start = function_with_setup;		
}

function _olympus_add_hook_after_suite_finish(fn, context){
	var function_with_setup = _olympus_hook_set_up(fn, context)
	global._olympus_test_manager._function_to_call_on_suite_finish = function_with_setup;			
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
	if (variable_global_exists("_olympus_test_manager") && is_struct(global._olympus_test_manager)){
		var current_test = global._olympus_test_manager.get_current_test();
		var callback_name = current_test[$ callback_struct_variable_name];
		var mediator_id = global._olympus_test_manager.get_current_test()._mediator_id; 
		var callback_handle = (mediator_id == id) ? variable_instance_get(id, callback_name) : function(){_olympus_console_log("This mediator already timed out:", object_get_name(object_index))};
	}
	return callback_handle;
}

#endregion

///@arg {string} message
///@arg {olympus_error_code} error_code
///@arg {struct} [info] Any additional information that is packaged in a struct
///@arg {string[]} [stacktrace]
function _Olympus_Test_Error(error_message, error_code) constructor{
	message = error_message;
	code  = error_code;	
	if (argument_count > 2) {
		if (!is_undefined(argument[2])){
			variable_instance_set(self, "info", argument[2]);
		}
	}	
	if (argument_count > 3) {
		if (!is_undefined(argument[3])){
			variable_instance_set(self, "stacktrace", argument[3]);
		}
	}
}

///@description Struct used to manage and execute all registered tests
function _Olympus_Test_Manager(suite_name, function_to_add_tests_and_hooks, options) constructor {
	_olympus_forbid_change_during_testing();
	//TODO: The reference should be managed by the meta controller when it is implemented.
	global._olympus_test_manager = self;
	_tests = [];
	_startTime=undefined;
	_function_to_call_on_suite_finish= undefined; // User-provided function to execute when all tests have concluded.
	_function_to_call_on_suite_start = undefined; // User-provided function to execute before all tests start.
	_current_test_index = -1;
	_default_timeout = 60000; 
	_skip_user_feedback_tests  = false;
	_bail_on_fail_or_crash = false;
	_completion_time = undefined;
	_suite_name = "unnamed_suite";
	_global_resolution_callback_name = "_olympus_test_resolution_callback";
	_global_rejection_callback_name = "_olympus_test_rejection_callback";
	_dependency_chain_last_test_name = "";
	_dependency_chain_active = false;
	_allow_uncaught = false;

	///@param {String} suite_name The name of the suite and the summary file
	///@param {function} function_to_add_tests_and_hooks
	///@param {Struct} options {abandon_unfinished_record:bool, skip_user_feedback_tests:bool, test_interval_milis: number, suppress_debug_logging:bool, global_resolution_callback_name: string, global_rejection_callback_name: string}
	_set_up_with_options = function(suite_name, function_to_add_tests_and_hooks, options){		
		var global_timeout_millis = options[$ "global_timeout_millis"];
		if (is_numeric(global_timeout_millis)){
			_default_timeout = global_timeout_millis;
		}		
		
		var context = options[$ "context"];
		if (is_struct(context)){
			function_to_add_tests_and_hooks = method(context, function_to_add_tests_and_hooks);
		}		
		function_to_add_tests_and_hooks();
		_suite_name = suite_name;
		 global._olympus_summary_manager = new _Olympus_Summary_Manager(_suite_name);
		
		_olympus_create_test_controller();
		
		date_set_timezone(timezone_utc);
		_startTime = current_time;

		var allow_uncaught = options[$ "allow_uncaught"];
		if (allow_uncaught){
			_allow_uncaught = true;
		}

		var abandon_unfinished_record = options[$ "abandon_unfinished_record"];
		if (abandon_unfinished_record || _allow_uncaught) {
			global._olympus_summary_manager.initialize_summary();
		}
		else{
			var ignore_if_completed = options[$ "ignore_if_completed"];			
			global._olympus_summary_manager.load_previous_summary(ignore_if_completed);			
		}
		
		var skip_user_feedback_tests = options[$ "skip_user_feedback_tests"];
		if (skip_user_feedback_tests) {
			_skip_user_feedback_tests = true;
		}
		
		var test_interval_milis = options[$ "test_interval_milis"];
		if (is_numeric(test_interval_milis)){
			with _olympus_async_test_controller{
				var _interval_between_tests_in_seconds = real(test_interval_milis)/1000
				_interval_between_tests = _interval_between_tests_in_seconds;
			}
		}
		
		var suppress_debug_logging  = options[$ "suppress_debug_logging"];
		global._olympus_debug_logging_suppressed = suppress_debug_logging;
		
		var global_resolution_callback_name = options[$ "global_resolution_callback_name"];
		if (is_string(global_resolution_callback_name)){
			_global_resolution_callback_name = global_resolution_callback_name;
		}
		
		var global_rejection_callback_name = options[$ "global_rejection_callback_name"];
		if (is_string(global_rejection_callback_name)){
			_global_rejection_callback_name = global_rejection_callback_name;
		}
		
		var bail_on_fail_or_crash = options[$ "bail_on_fail_or_crash"];
		if (bail_on_fail_or_crash){
			_bail_on_fail_or_crash = true;
		}
		
		if (!_allow_uncaught){
			exception_unhandled_handler(function(ex){
				var olympus_error = new _Olympus_Test_Error("Unhandled exception", olympus_error_code.unhandled_exception, ex);
				global._olympus_summary_manager.update_tests_crashed(olympus_error);
				global._olympus_summary_manager.write_summary_to_file();
				show_message(ex);
			})
		}
		
		show_debug_overlay(true);
		execute();
	}

	///@description Execute the n-th test struct
	///@param {Integer} [test_index]
	execute = function (test_index) {
		if (is_undefined(test_index)){
			// We are starting from the beginning
			if (is_method(_function_to_call_on_suite_start)){
				_function_to_call_on_suite_start(global._olympus_summary_manager.get_summary());
			}
			test_index = global._olympus_summary_manager.get_beginning_test_index();
		}
		else{
			_olympus_console_log("Executing test #", test_index);
		}

		if(test_index == array_length(_tests)){
			// Then we have completed all tests
			var end_status = olympus_summary_status_completed;
			if (_bail_on_fail_or_crash && global._olympus_summary_manager.has_failure_or_crash()){
				end_status = olympus_summary_status_bailed;
			}
			_conclude_tests(end_status);
		}
		else{
			_current_test_index = test_index;
		}		
	}
	
	get_global_resolution_callback_name = function(){
		return _global_resolution_callback_name;
	}
	
	get_global_rejection_callback_name = function(){
		return _global_rejection_callback_name;
	}

	_clean_up = function() {
		show_debug_overlay(false);		
		with _olympus_async_test_controller{
			instance_destroy();
		}
		delete global._olympus_summary_manager;
		delete global._olympus_test_manager;
	}	
	
	///@description Once all tests have passed, failed, or timed out, call this function.
	_conclude_tests = function(status) {
		_completion_time = current_time - _startTime;
		global._olympus_summary_manager.complete(status);
		if (!_allow_uncaught){
			exception_unhandled_handler(undefined);	//Restore the exception handler to default state.
		}
		if (is_method(_function_to_call_on_suite_finish)){
			_function_to_call_on_suite_finish(global._olympus_summary_manager.get_summary());
		}
		_clean_up();
	}
	
	///@description Adds a test to this manager and return the test index
	///@param {Struct} test
	add_test = function(test){
		var test_name = test._name
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

	_set_up_with_options(suite_name, function_to_add_tests_and_hooks, options)
}

///@description Struct used to hold the registered test data for later execution
///@param {String} name
///@param {Function} fn
///@param {Function} [resolution_fn=noone] The function to be executed when the async function resolves
///@param {String} [prompt=noone] The prompt to instruct the tester
///@param {struct} [options] {resolution_callback_name, rejection_callback_name}
function _Olympus_Test(name, fn) constructor {
	_olympus_forbid_adding_outside_suite();
	_olympus_forbid_change_during_testing();	

	var options =  argument_count > 4 ? argument[4] : {};
	var resolution_callback_name = options[$"resolution_callback_name"];
	var rejection_callback_name = options[$"rejection_callback_name"];
	var context = options[$"context"];
	var resolution_context = options[$"resolution_context"];
	var timeout_millis = options [$"timeout_millis"];

	_name = name;
	_test_fn = fn;
	_test_fn_context = is_struct(context) ? context : undefined;
	var test_index = global._olympus_test_manager.add_test(self);
	_index = test_index;
	disabled = false;
	_counting_time_out = true;
	status = olympus_test_status_unstarted;
	_err = undefined;
	_resolution_fn = argument_count > 2 ? argument[2] : noone;
	_is_async = is_method(_resolution_fn);	
	_resolution_fn_context = is_struct(resolution_context) ? resolution_context : undefined;
	_resolution_callback_name = is_string(resolution_callback_name) ? resolution_callback_name : "";
	_rejection_callback_name = is_string(rejection_callback_name) ?  rejection_callback_name : "";
	timeout = is_numeric(timeout_millis)? timeout_millis : global._olympus_test_manager._default_timeout;
	_start_time = undefined;
	_completion_time = undefined;
	_user_feedback_prompt = argument_count > 3 ? argument[3] : noone;	
	_user_feedback_required = _user_feedback_prompt != noone;
	_mediator_id = -1;
	_dependencies = [];
	
	_get_non_passing_dependency_names = function(){
		var non_passing_dependency_names = [];
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
		if (is_struct(_test_fn_context)){
			_test_fn = method(_test_fn_context, _test_fn);
		}
				
		if (_is_async && _resolution_fn != noone &&  is_struct(_resolution_fn_context)){
			_resolution_fn = method(_resolution_fn_context, _resolution_fn);
		}						
	}
	
	_set_timeout = function(milliseconds){
		timeout = milliseconds;
	}

	_create_resolution_callback = function(){	
		return method(self, function(){			
			if (status == olympus_test_status_running){
				try{
					var _param_array = [];
					for (var i = 0; i < argument_count; i ++){
						_param_array[i] = argument[i];
					}					
					_resolution_fn(_param_array);
					
					if (_user_feedback_required){
						status = olympus_test_status_getting_user_feedback;
						_set_completion_time(); //Stop incremention the completion time as we don't know how long the user will take to complete the test
						var user_feedback_handle = _get_user_feedback_async();
						with _olympus_async_test_controller{
							_user_feedback_handle = user_feedback_handle;
						}							
					}
					else{
						resolve();
					}										
				}
				catch(err){					
					reject(err, olympus_error_code.failed_resolution);
				}
			}
			else{
				_olympus_console_log("Resolution was already attempted for:", _name);
			}
		});
	}

	///@desc Displays the user feedback prompt, and returns the async handle
	_get_user_feedback_async = function(){
		var prompt =  _user_feedback_prompt  + " (Type 'Pass' and hit 'OK' to pass, or enter your own message and hit 'OK' to fail the test. 'Cancel' will always fail the test.)"
		var user_feedback_handle = get_string_async(prompt, _olympus_user_feedback_confirm_message);
		return user_feedback_handle;
	}

	_set_up = function(){
		status = olympus_test_status_running;
		_start_time = current_time;
		global._olympus_summary_manager.update_tests(get_summary());
		global._olympus_summary_manager.update_progress(_index, _name);
		global._olympus_summary_manager.write_summary_to_file();			
	}

	/// @desc return a copy of the individual test's summary
	get_summary = function(){
		var individual_test_summary = {
			index: _index,
			name: _name,
			millis: _completion_time,
			status: status
		}
		if (_err){
			individual_test_summary[$"err"] = _err;
		}
		return individual_test_summary;
	}

	_tear_down = function() {
		// After we are done testing 
		if (is_undefined(_completion_time)){
			_set_completion_time();
		}								
		global._olympus_summary_manager.update_tests(get_summary());		
		global._olympus_summary_manager.update_progress(_index, _name);
		global._olympus_summary_manager.update_tallies();
		global._olympus_summary_manager.write_summary_to_file();
	}

	_update_err_for_disabling_reasons = function(){
		if (disabled){
			_err = new _Olympus_Test_Error("Skipped by xolympus_add_*", olympus_error_code.skip_with_x);
		}		
		else if (global._olympus_test_manager._bail_on_fail_or_crash && global._olympus_summary_manager.has_failure_or_crash()){
			_err = new _Olympus_Test_Error("Skipped because of bail", olympus_error_code.skip_with_bail);
		}
		else if	(_user_feedback_required & global._olympus_test_manager._skip_user_feedback_tests){
			_err = new _Olympus_Test_Error("Skipped because user feedback is suppressed", olympus_error_code.skip_with_suppress);
		}
		else if (array_length(_get_non_passing_dependency_names()) > 0){
			_err = new _Olympus_Test_Error("Skipped because dependency did not pass", olympus_error_code.skip_with_dependency, _get_non_passing_dependency_names());
		}		
	}	
	
	///@description Run test
	run = function (){
		_set_up();
		_log_status();
		_bind_callback_context();
		_update_err_for_disabling_reasons();

		if (_err){
			_skip();			
		}
		else{
			try {
				if(_is_async){
					_attach_callback_to_mediator();
				}
				else{
					_test_fn(); 
					if  ((current_time - _start_time) > timeout) {
						reject( new _Olympus_Test_Error("Sync Test Exceeded Timeout: " + string(timeout)), olympus_error_code.timeout);
					}
					else{
						resolve();
					}
				}
			} catch (err){
				var code = olympus_error_code.failed_sync;
				if (_is_async){
					code = olympus_error_code.failed_async_mediator_spawning;
				}				
				reject(err, code);
			}
		}
	}		

	_attach_resolution_to_mediator = function(mediator_id, resolution_callback){
		if (_resolution_callback_name == ""){
			_resolution_callback_name = global._olympus_test_manager.get_global_resolution_callback_name();
		}
		variable_instance_set(mediator_id, _resolution_callback_name, resolution_callback);
	}

	_attach_rejection_to_mediator = function(mediator_id){
		if (_rejection_callback_name == ""){
			_rejection_callback_name = global._olympus_test_manager.get_global_rejection_callback_name();
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
		var test_finish_time = current_time;
		var test_duration = test_finish_time - _start_time;
		_completion_time = test_duration;
		_counting_time_out = false;
	}

	/// @desc By default, log the result as failure. If _allow_uncaught, throw the error instead
	/// @param {Error} err Error that caused the test to fail
	/// @param {olympus_error_code} [code]
	reject = function(err){
			if (global._olympus_test_manager._allow_uncaught){
				throw(err);
			}
			else{
				var code = argument_count > 1 ? argument[1] : olympus_error_code.user_defined;
				status = olympus_test_status_failed;			
				err = _convert_user_error_to_olympus_error(err, code);
				_olympus_console_log(err.message);
				_err = err;
				_done();
			}
	}
	
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
		if (global._olympus_test_manager._dependency_chain_active) {
			var last_dependency_name = global._olympus_test_manager._dependency_chain_last_test_name;
			if (last_dependency_name != ""){
				array_push(dependency_names, last_dependency_name);
			}
		}

		array_sort(dependency_names, true);
		var previous_dependency_name = "";
		for (var i = 0; i < array_length(dependency_names); i++){
			var dependency_name = dependency_names[i];
			if (previous_dependency_name != dependency_name){
				var dependency_test = global._olympus_test_manager.get_test_by_name(dependency_name);
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
		if (global._olympus_test_manager._dependency_chain_active){
			global._olympus_test_manager._dependency_chain_last_test_name = _name;
		}		
	#endregion
}

///@description Struct used to hold the test summary for resuming tests and export
function _Olympus_Summary_Manager(suite_name) constructor{
	//TODO: The reference should be managed by the meta controller when it is implemented.
	global._olympus_summary_manager = self;
	static _config = { 
		runtime: {
			version: GM_runtime_version,
			optimized : code_is_compiled()
		},
		os: {
			id: os_type
		},
		project:{
			name: game_project_name,
			config: os_get_config(),
			version: GM_version,
			debug: debug_mode 
		},
	};

	_summary = {};
	
	///@description Initialize a new summary
	initialize_summary = function() {
		_purge_record();		
		_summary = {
			config: _config,
			tallies: {
				total:  array_length(global._olympus_test_manager._tests),
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
			name: _get_safe_name(global._olympus_test_manager._suite_name)
		}
		_initialize_tests();
	}
	
	_initialize_tests = function(){
		var tests = global._olympus_test_manager._tests;
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
		||summary.config.os.id != os_type
		||summary.config.project.name != game_project_name
		|| summary.config.project.version != GM_version
		|| summary.config.project.debug != debug_mode
		|| summary.tallies.total != array_length(global._olympus_test_manager._tests)
		|| summary.config.runtime.version != GM_runtime_version
		|| summary.config.runtime.optimized != code_is_compiled()
	}
	
	///@description Returns the unit index to begin the test suite with
	get_beginning_test_index = function(){
		var beginning_test_index = 0; 
		if (_summary.status == olympus_summary_status_running) {
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
					var crashed_test = _summary.tests[_summary.progress.last_test_index];
					if  (crashed_test[$ "status"] != olympus_test_status_crashed) {
						_olympus_console_log("Last run had a crash with uncaught exception.");
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
		if (!global._olympus_test_manager._allow_uncaught){		
			var summary = argument_count > 0 ? argument[0] : _summary;
			var file_name = argument_count > 1 ? argument[1] : _get_summary_file_name();	
			var output_string = json_stringify(summary);
			var fh = file_text_open_write(file_name);
			file_text_write_string(fh,output_string);
			file_text_close(fh);

			if (os_type == os_switch){
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
	///@arg {Integer} test_index
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
		var crashed_test_summary = global._olympus_test_manager._tests[_summary.progress.last_test_index].get_summary();
		crashed_test_summary.status = olympus_test_status_crashed;
		variable_struct_remove(crashed_test_summary, "millis");
		crashed_test_summary[$"err"] = olympus_error;
		update_tests(crashed_test_summary);
	}
	
	///@desc Return the copy of the summary struct
	get_summary = function(){
		return  json_parse(json_stringify(_summary));
	}
	
	///@desc Return the copy of the summary struct
	has_failure_or_crash = function(){
		return (_summary.tallies.failed > 0 || _summary.tallies.crashed >0);				
	}	

	_get_prettified_summary = function(){
		var _summary = get_summary();
		variable_struct_remove(_summary, "progress");
		variable_struct_remove(_summary, "config");
		return _summary;
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
		
	_set_name(suite_name);
}

