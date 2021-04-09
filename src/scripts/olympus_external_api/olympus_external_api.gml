/**
@desc Starts a named test suite
@param {string} suite_name The name of the suite
@param {function} function_to_add_tests_and_hooks a function that adds all the tests and hooks 
@param {struct} [olympus_suite_options] Optional configuration to pass in 
	@property {boolean}	[abandon_unfinished_record=false] - Enabling this disables the suite from resuming unfinished records that are caused by runner existing during the test.
	@property {boolean}	[skip_user_feedback_tests=false] - Enabling this skips tests that requires user feedback.
	@property {boolean}	[suppress_debug_logging=false] - Enabling this suppresses Olympus from logging to the IDE Output tab.
	@property {number}	[test_interval_milis=0] - Adds a delay between each test. Can be used to allow an audio or a visual cue to be played between tests.
	@property {string}		[global_resolution_callback_name="callback"] - Name of the instance variable for the resolution callback
	@property {string}		[global_rejection_callback_name="reject"] - Name of the instance variable for the rejection callback
	@property {boolean}	[bail_on_fail_or_crash=false] - Enabling this will skip the rest of the tests if an earlier test fails or crashes
	@property {struct} [context] The binding context for function_to_add_tests_and_hooks. The default uses the calling context.
	@property {number} [global_timeout_millis=60000] If any test is not able to resolve within this many milliseconds, the test will be failed.
	@property {boolean} [allow_uncaught=false] By default, Olympus catches uncaught error and record it. Enabling this allows uncaught error to be thrown instead and will stop recording test summaries or resuming unfinished records. 
	@property {boolean} [ignore_if_completed=false] Enabling this will ignore re-running the suite if the suite has been completed previously. 
*/
function olympus_run(suite_name, function_to_add_tests_and_hooks) {
	function_to_add_tests_and_hooks_with_context = method(self, function_to_add_tests_and_hooks);
	var olympus_suite_options = argument_count > 2 ? argument[2] : {};
	return new _Olympus_Test_Manager(suite_name,function_to_add_tests_and_hooks_with_context, olympus_suite_options);
}

#region olympus_suite_options
	#macro olympus_suite_options_abandon_unfinished_record abandon_unfinished_record
	#macro olympus_suite_options_skip_user_feedback_tests skip_user_feedback_tests
	#macro olympus_suite_options_suppress_debug_logging suppress_debug_logging
	#macro olympus_suite_options_test_interval_milis test_interval_milis
	#macro olympus_suite_options_global_resolution_callback_name global_resolution_callback_name
	#macro olympus_suite_options_global_rejection_callback_name global_rejection_callback_name
	#macro olympus_suite_options_bail_on_fail_or_crash bail_on_fail_or_crash
	#macro olympus_suite_options_context context
	#macro olympus_suite_options_global_timeout_millis global_timeout_millis 
	#macro olympus_suite_options_allow_uncaught allow_uncaught
	#macro olympus_suite_options_ignore_if_completed ignore_if_completed
#endregion

/** 
@desc Adds a unit test with a name and a function with synchronous logic to execute
@param {string} name Name of the test
@param {function} function_to_execute_synchronous_logic The function to execute the synchronous logic
@param {struct} [olympus_test_options]
	@property {struct} [context] The binding context for function_to_execute_synchronous_logic. The default uses the calling context.
	@property {string | string[]} [dependency_names] Names of tests whose failure will cause this test to be skipped
	@property {number} [timeout_millis=60000]  If this test is not able to resolve within this many milliseconds, the test will be failed.
 */
function olympus_add_test(name, function_to_execute_synchronous_logic){	
	function_to_execute_synchronous_logic = method(self, function_to_execute_synchronous_logic);
	var olympus_test_options = argument_count > 2 ? argument[2] : {};
	var this_test = new _Olympus_Test(name, function_to_execute_synchronous_logic, noone, noone, olympus_test_options);
	return this_test;
}

#region olympus_test_options
	#macro olympus_test_options_resolution_callback_name resolution_callback_name
	#macro olympus_test_options_rejection_callback_name rejection_callback_name
	#macro olympus_test_options_dependency_names dependency_names
	#macro olympus_test_options_context context
	#macro olympus_test_options_resolution_context resolution_context
	#macro olympus_test_options_timeout_millis timeout_millis
#endregion

/** 
@desc Adds a unit test with a name and a function that spawns an object that mediates async logic
@param {string} name Name of the test
@param {function} function_to_spawn_object The function to spawn the mediator object
@param {function} [function_to_execute_at_resolution] The function to be executed when the async function resolves. The async result can be passed to this function for consumption.
@param {struct} [olympus_test_options]
	@property {string} [resolution_callback_name] If you have not defined a global_resolution_callback_name or want to overwrite that, specify it here
	@property {string} [rejection_callback_name] If you have not defined a global_rejection_callback_name or want to overwrite that, specify it here
	@property {string | string[]} [dependency_names] Names of tests whose failure will cause this test to be skipped
	@property {struct} [contex] The binding context for function_to_spawn_object. The default uses the calling context.
	@property {struct} [resolution_context] The binding context for function_to_execute_at_resolution	
	@property {number} [timeout_millis=60000]  If this test is not able to resolve within this many milliseconds, the test will be failed.
 */
function olympus_add_async_test(name, function_to_spawn_object){
	function_to_spawn_object = method(self, function_to_spawn_object);
	var function_to_execute_at_resolution = argument_count > 2 ? argument[2] : function(){};
	function_to_execute_at_resolution = method(self, function_to_execute_at_resolution);
	var olympus_test_options = argument_count > 3 ? argument[3] : {};
	var this_test = new _Olympus_Test(name, function_to_spawn_object, function_to_execute_at_resolution, noone, olympus_test_options);
	return this_test;
}


/** 
@desc Similar to olympus_add_async_test, but also specifies a text prompt to user to allow the user to fail the test and provide feedback
@param {string} name Name of the test
@param {string} prompt The text prompt to instruct the user about the pass/fail creteria
@param {function} function_to_spawn_object The function to spawn the mediator object
@param {function} [function_to_execute_at_resolution] The function to be executed when the async function resolves. The async result can be passed to this function for consumption.
@param {struct} [olympus_test_options]
	@property {string} [resolution_callback_name] If you have not defined a global_resolution_callback_name or want to overwrite that, specify it here
	@property {string} [rejection_callback_name] If you have not defined a global_rejection_callback_name or want to overwrite that, specify it here
	@property {string | string[]} [dependency_names] Names of tests whose failure will cause this test to be skipped
	@property {struct} [context] The binding context for function_to_spawn_object. The default uses the calling context.
	@property {struct} [resolution_context] The binding context for function_to_execute_at_resolution. The default uses the calling context.
	@property {number} [timeout_millis=60000]  If this test is not able to resolve within this many milliseconds, the test will be failed.	
 */
function olympus_add_async_test_with_user_feedback(name, prompt, function_to_spawn_object){	
	function_to_spawn_object = method(self, function_to_spawn_object);
	var function_to_execute_at_resolution = argument_count > 3 ? argument[3] : function(){};
	function_to_execute_at_resolution = method(self, function_to_execute_at_resolution);
	var olympus_test_options = argument_count > 4 ? argument[4] : {};
	var this_test = new _Olympus_Test(name, function_to_spawn_object, function_to_execute_at_resolution, prompt, olympus_test_options);
	return this_test;
}

/** 
@desc Syntactic sugar to skip a test added by olympus_add_test
@param {string} name Name of the test
@param {*} [...] 
 */
function xolympus_add_test(name){	
	var this_test = olympus_add_test(name, function(){});
	this_test.disabled = true;
	return this_test;
}

/** 
@desc Syntactic sugar to skip a test added by olympus_add_async_test
@param {string} name Name of the test
@param {*} [...] 
 */
function xolympus_add_async_test(name){
	var this_test = xolympus_add_test(name);
	return this_test;
}

/** 
@desc Syntactic sugar to skip a test added by olympus_add_async_test_with_user_feedback
@param {string} name Name of the test
@param {*} [...] 
 */
function xolympus_add_async_test_with_user_feedback(name){	
	var this_test = xolympus_add_async_test(name);
	return this_test;
}

/**
@desc Set a function to be excuted before each test starts. The test summary struct is passed to this function as the first argument.
@param {function} function_to_execute The function to execute
@param {struct | instance_id } [context] The optional context to bind the function to. The default uses the calling context.
*/
function olympus_add_hook_before_each_test_start(function_to_execute){
	var context = argument_count > 1 ? argument[1] : self
	_olympus_add_hook_before_each_test_start(function_to_execute, context);
}

/** 
@desc Set a function to be excuted after each test finishes. The test summary struct is passed to this function as the first argument.
@param {function} function_to_execute The function to execute
@param {struct | instance_id } [context] The optional context to bind the function to. The default uses the calling context.
*/
function olympus_add_hook_after_each_test_finish(function_to_execute){
	var context = argument_count > 1 ? argument[1] : self
	_olympus_add_hook_after_each_test_finish(function_to_execute, context);
}

/**
@desc Set a function to be excuted before the suite starts. The suite summary struct is passed to this function as the first argument.
@param {function} function_to_execute The function to execute
@param {struct | instance_id } [context] The optional context to bind the function to. The default uses the calling context.
*/
function olympus_add_hook_before_suite_start(function_to_execute){
	var context = argument_count > 1 ? argument[1] : self
	_olympus_add_hook_before_suite_start(function_to_execute, context);
}

/** 
@desc Set a function to be excuted after the suite finishes. The suite summary struct is passed to this function as the first argument.
@param {function} function_to_execute The function to execute
@param {struct | instance_id } [context] The optional context to bind the function to. The default uses the calling context.
 */
function olympus_add_hook_after_suite_finish(function_to_execute){
	var context = argument_count > 1 ? argument[1] : self
	_olympus_add_hook_after_suite_finish(function_to_execute, context);
}

/** 
@desc Return a copy of the up-to-date suite summary struct. 
*/
function olympus_get_current_suite_summary(){
	return global._olympus_summary_manager.get_summary();
}

/** 
@desc Return a copy of the array that contains all the up-to-date test summaries. 
*/
function olympus_get_current_test_summaries(){
	return global._olympus_summary_manager.get_summary().tests;
}

/** 
@desc Return the status of a unit test. 
@param {struct} test_summary The test summary struct
*/
function olympus_get_test_status(test_summary){	
	return test_summary.status;
}

/** 
@desc Return the name of a unit test. 
@param {struct} test_summary The test summary struct
*/
function olympus_get_test_name(test_summary){
	return test_summary.name;
}

/** 
@desc Tests added between olympus_test_dependency_chain_begin() and olympus_test_dependency_chain_end() are sequentially dependent on each self
*/
function olympus_test_dependency_chain_begin(){
	global._olympus_test_manager.dependency_chain_begin();
}

/** 
@desc Tests added between olympus_test_dependency_chain_begin() and olympus_test_dependency_chain_end() are sequentially dependent on each self
*/
function olympus_test_dependency_chain_end(){
	global._olympus_test_manager.dependency_chain_end();
}

#region Macros
/**
@desc Calls the resolution function of the current test
@arg {*} [args...] Can take any arguments
 */
#macro olympus_test_resolve \
var olympus_resolve_callback_handle = _olympus_get_resolve_function_handle(); \
olympus_resolve_callback_handle

/**
@desc Calls the rejection function of the current test
@arg {*} [args...] Can take any arguments
 */
#macro olympus_test_reject \
var olympus_reject_callback_handle = _olympus_get_reject_function_handle(); \
olympus_reject_callback_handle


/** 
@desc In the test summary struct, the "status" key uses the following macros 
 */
 #macro olympus_test_status_unstarted  "unstarted"
 #macro olympus_test_status_running  "running"
 #macro olympus_test_status_getting_user_feedback "getting_user_feedback"
 #macro olympus_test_status_passed  "passed"
 #macro olympus_test_status_failed  "failed"
 #macro olympus_test_status_skipped  "skipped"
 #macro olympus_test_status_crashed "crashed"

/** 
@desc In the error struct, the "code" field uses the following enums
 */
enum olympus_error_code{
	unhandled_exception = 0,
	uncaught_crash = 1,
	skip_with_x = 2,
	skip_with_suppress = 3,
	skip_with_dependency = 4,
	skip_with_bail = 5,
	timeout = 6,
	user_rejection = 7,
	user_cancellation = 8,
	failed_resolution = 9,
	failed_async_mediator_spawning = 10,
	failed_sync = 11,
	user_defined = 12
}

#endregion