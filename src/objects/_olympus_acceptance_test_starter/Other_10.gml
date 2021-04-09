/// @desc This is the self test to ensure that Olympus is managing test units correctly. 
/// The test is run with the Olympus_acceptance_test config, and should need to reboot 1 time to complete	
olympus_run("Olympus Acceptance Test", function(){

	
	olympus_add_test("P_Forbid_change_during_test", function(){
		if (global._olympus_test_manager.get_current_test()._index != 0) {
			show_error("This test must be the 0th test!", true);
		}		
		try {
			olympus_add_test("attempting to add a test during an on-going test", function(){});
			show_error("This should not execute as the prior statement should have thrown an error", true);
		}
		catch(err){
			_olympus_acceptance_test_expect_eq(err, _olympus_forbid_change_during_testing_err);
		}		
				
		try {
			olympus_run("attempting to run a test during an on-going test", function(){});
			show_error("This should not execute as the prior statement should have thrown an error", true);
		}
		catch(err){
			_olympus_acceptance_test_expect_eq(err, _olympus_forbid_change_during_testing_err);
		}
		
		try {
			olympus_add_hook_before_suite_start( function() {
				show_debug_message("attempting to set a hook during an on-going test");
			})
			show_error("This should not execute as the prior statement should have thrown an error", true);
		}
		catch(err){
			_olympus_acceptance_test_expect_eq(err, _olympus_forbid_change_during_testing_err);
		}
	});
	
	foo = "foo";
	olympus_add_test("P_inhertied_context_test", function(){
		if (global._olympus_test_manager.get_current_test()._index != 1) {
			show_error("This test must be the 1st test!", true);
		}				
		_olympus_acceptance_test_expect_eq(foo, "foo", "foo is declared in the test registration context and should be avaialble to the test");
		_olympus_acceptance_test_expect_eq(instance_exists(_olympus_acceptance_test_starter), false, "_olympus_acceptance_test_test_starter should be destroyed by this point");
		_olympus_acceptance_test_expect_eq(test_starter_instance_variable, "test_starter_instance_variable", "But its instance variable test_starter_instance_variable should still be available"); 
	});

	olympus_add_test("P_custom_context_test", function(){
		if (global._olympus_test_manager.get_current_test()._index != 2) {
			show_error("This test must be the 2nd test!", true);
		}				
		_olympus_acceptance_test_expect_eq(foo, "overwritten", "Foo is overwritten by the custom context.");
		_olympus_acceptance_test_expect_eq(bar, "bar", "Bar is provided by the custom context.");
	}, {olympus_test_options_context: {bar: "bar", foo: "overwritten"}});

	olympus_add_async_test("F_Time_out", function(){
		if (global._olympus_test_manager.get_current_test()._index != 3) {
			show_error("This test must be the 3rd test!", true);
		}				
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async)
	}, 
	function(){}, 
	{
		olympus_test_options_timeout_millis: 1
	});		

	var user_feedback_test_name = "B_User_feedback_test";
	if (os_get_config() == "Olympus_dev"){
		user_feedback_test_name = "S_User_feedback_test"
	}
	olympus_add_async_test_with_user_feedback(user_feedback_test_name, "pass this user feedback test?", function(){
		if (global._olympus_test_manager.get_current_test()._index != 4) {
			show_error("This test must be the 4th test!", true);
		}				
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async)
	}, function(){
		if (os_get_config() == "Olympus_dev"){
			show_error("This should not show because this test is supposed to be skipped due to dev config suppressing user feedback!", true)
		}
	});
	
	var non_existing_test_name = "non_existing_test";
	try{
		olympus_add_test("P_non_existing_dependency", function(){
			_olympus_console_log("This test should cause the runner to crash if uncaught, but since we are catching it, this message should be logged and the test should also pass");
		}, {olympus_test_options_dependency_names: non_existing_test_name})
	}
	catch(err){
		_olympus_acceptance_test_expect_eq(err.test_name, non_existing_test_name);
	}

	olympus_add_async_test("F_Time_out_global", function(){
		var mediator_id = _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async);
		with mediator_id{
			_olympus_console_log("Should time out as the global timeout is set to be under .5 seconds");
			alarm[0] = room_speed * .5;
		}
		return mediator_id;
	});		

	var non_unique_name = "P_non_unique_name";
	olympus_add_test(non_unique_name, function(){});
	try{
		olympus_add_test(non_unique_name, function(){show_error("Should not execute because of non-unique name", true)});
	}
	catch(err){
		_olympus_acceptance_test_expect_eq(err.name, non_unique_name);
	}	

	var dependency_name = "P_dependee";
	var depender_name = "P_depender";
	olympus_add_test(dependency_name, function(){});
	olympus_add_test(depender_name, function(){}, {olympus_test_options_dependency_names: dependency_name});
	
	var failed_dependency_name = "F_dependee";
	var depender_name = "S_depender";
	olympus_add_test(failed_dependency_name, function(){ throw("Causing skipping for: S_depender")});
	olympus_add_test( depender_name, function(){}, {olympus_test_options_dependency_names: [dependency_name, failed_dependency_name]});
	olympus_add_test( "S_depender_grandchild", function(){}, {olympus_test_options_dependency_names: [depender_name]});	
	
	var skipped_dependency_name = "S_dependee";
	var depender_name = "S_depender_S";
	xolympus_add_test(skipped_dependency_name, function(){ show_error("Being skipped, which should cause S_depender_S to be skipped", true)});
	olympus_add_test( "S_depender_S", function(){}, {olympus_test_options_dependency_names: [dependency_name, skipped_dependency_name]});	
	

	#region dependency chaining
	olympus_test_dependency_chain_begin();
	olympus_add_test("F_chain_1", function(){ throw("Causing the rest of the chain to be skipped")});	
	olympus_add_test("S_chain_2", function(){});
	olympus_add_test("S_chain_3", function(){});
	olympus_test_dependency_chain_end();
	olympus_add_test("P_chain_4", function(){ _olympus_console_log("Outside of the chain, so should pass")});
	olympus_test_dependency_chain_begin();
	olympus_add_test("P_chain_5", function(){_olympus_console_log("Should all pass")});	
	olympus_add_test("P_chain_6", function(){_olympus_console_log("Should all pass")});
	olympus_add_test("P_chain_7", function(){_olympus_console_log("Should all pass")});
	olympus_test_dependency_chain_end();	
	#endregion
	
	olympus_add_test("F", function(){
		throw("Throwing a custom error to cause the test to fail.");
	});
	
	olympus_add_async_test("F_mediator_rejection", function(){
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async_reject);
	});	
	
	olympus_add_async_test("F_mediator_rejection_with_custom_name", function(){
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async_reject);
	}, function(){},
	{olympus_test_options_rejection_callback_name: "any_name"}
	);		

	xolympus_add_test("S", function(_done){
		show_error("This should not show because this test is skipped!", true);
	});
	
	olympus_add_async_test("P_overwriting_resolution_callback_name", function(){
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async_different_callback_name)
	}, function(){
		show_debug_message("Inhertied context should also be available for the resolution function");
		_olympus_acceptance_test_expect_eq(foo, "foo");
		_olympus_acceptance_test_expect_eq(test_starter_instance_variable, "test_starter_instance_variable"); 		
	}, {olympus_test_options_resolution_callback_name: "_object_specific_callback"});	

	olympus_add_async_test("P_inhertied_context_test_for_resolution", function(){
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async)
	}, function(){
		show_debug_message("Inhertied context should also be available for the resolution function");
		_olympus_acceptance_test_expect_eq(foo, "foo");
		_olympus_acceptance_test_expect_eq(test_starter_instance_variable, "test_starter_instance_variable"); 		
	});

	olympus_add_async_test("F_async_resolution_and_parameter", function(){
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async)
	}, function(response_array){
		var res = response_array[0];
		_olympus_acceptance_test_expect_eq("GOODBYE", res, "_olympus_acceptance_test_helper_async passes HELLO as a result to the callback");
	});
	
	olympus_add_async_test("F_custom_context_test", function(){
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async)
	}, function(response_array){
		var res = response_array[0];
		var res2 = response_array[1];
		_olympus_acceptance_test_expect_eq("HELLO", res);
		_olympus_acceptance_test_expect_eq("WORLD", res2);
		_olympus_acceptance_test_expect_eq(foo, "foo", "Expected to fail because foo is overwritten!");
	}, { olympus_test_options_resolution_context: {foo: "overwritten"}});	
	
	if (os_get_config() == "Olympus_dev"){
		_olympus_console_log("Skipping the crash case for dev config");
	}
	else{
		olympus_add_async_test("C_silent_crash", function(){
			show_debug_message("This simulates a message-less crash that termniates the runner.")
			game_end(); 
		});
	}

	olympus_add_test("F_post_crash", function(){
		_olympus_acceptance_test_expect_eq(3, 4, "Comparing 3 to 4");
	});

	xolympus_add_test("S_post_crash", function(){
		show_debug_message("Again, this should be skipped!");
	});

	olympus_add_test("P_post_crash", function(){
		_olympus_acceptance_test_expect_eq(true, true);
	});

	olympus_add_async_test("F_last_test", function(){
		if (global._olympus_test_manager.get_current_test()._index != (global._olympus_summary_manager.get_summary().tallies.total - 1)) {
			show_error("This test must be the last test!", true);
		}
		show_debug_message("Testing whether a mediator object that calls resolve function after the suites ends will cause a crash.");
		return _olympus_acceptance_test_instance_create(_olympus_acceptance_test_helper_async_different_callback_name);
	}, function(){
		show_debug_message("Inhertied context should also be available for the resolution function");
		_olympus_acceptance_test_expect_eq(foo, "foo");
		_olympus_acceptance_test_expect_eq(test_starter_instance_variable, "test_starter_instance_variable"); 		
	}, {
		olympus_test_options_resolution_callback_name: "_object_specific_callback",
		olympus_test_options_timeout_millis: 1
		});	

	olympus_add_hook_before_suite_start(function(summary){
			_olympus_console_log(summary);
	});

	olympus_add_hook_after_suite_finish( function(summary){
		var copied_summary = olympus_get_current_suite_summary();
		_olympus_acceptance_test_expect_struct_eq(summary, copied_summary);
		
		_olympus_console_log("Suite Finished");		
		if (os_get_config() == "Olympus_bail"){			
			//TODO: test in a separate suite when multi-suites became supported
			var expected_status = olympus_summary_status_bailed;
			var actual_status = summary.status;
			_olympus_acceptance_test_expect_eq(expected_status, actual_status);
			var expected_failures = 1;
			var expected_passes = 3;
			var expected_skipped = summary.tallies.total - expected_failures - expected_passes;
			_olympus_acceptance_test_expect_eq(expected_failures, summary.tallies.failed);
			_olympus_acceptance_test_expect_eq(expected_passes, summary.tallies.passed);
			_olympus_acceptance_test_expect_eq(expected_skipped, summary.tallies.skipped);
		}		
		else{
			var tests = olympus_get_current_test_summaries();
			for (var i = 0; i < array_length(tests); i++){
				var the_test = tests[i];
				var test_name = olympus_get_test_name(the_test);
				var expected_result_initial = string_char_at(test_name, 1);
				var expected_result;
				var actual_result_string = olympus_get_test_status(the_test);
				if (expected_result_initial != "B"){
					switch (expected_result_initial) {
						case "P":
							expected_result = olympus_test_status_passed;
							break;
						case "F":
							expected_result = olympus_test_status_failed;
							break;
						case "C":
							expected_result = olympus_test_status_crashed;
							break;
						case "S":
							expected_result = olympus_test_status_skipped;
							break;
						default:
							show_error("Test name initial is not expected: " + expected_result_initial, true);
							break;
					}
					_olympus_acceptance_test_expect_eq(expected_result, actual_result_string, test_name);
				}
				else{
					_olympus_acceptance_test_expect_eq( actual_result_string == olympus_test_status_passed || 
													actual_result_string == olympus_test_status_failed, 
													true, test_name);
				}
			}
		}
		show_message("Acceptance test passed!");
		game_end();
	});

	//TODO: test the context for hooks
	olympus_add_hook_before_each_test_start(function(summary){
		_olympus_console_log(summary)
	});

	olympus_add_hook_after_each_test_finish(function(summary){
		_olympus_console_log(summary)
	});
},
{
	//TODO: test the context in when meta scheduler is implemented.
	//olympus_suite_options_context: other,
	olympus_suite_options_abandon_unfinished_record: _should_abandon_record, 
	olympus_suite_options_skip_user_feedback_tests:  os_get_config() == "Olympus_dev", 
	olympus_suite_options_test_interval_milis: 0, 
	olympus_suite_options_suppress_debug_logging: false, 
	olympus_suite_options_bail_on_fail_or_crash: os_get_config() == "Olympus_bail",
	olympus_suite_options_global_rejection_callback_name: "any_rejection_name_i_want",
	olympus_suite_options_global_resolution_callback_name: "any_resolution_name_i_want",
	olympus_suite_options_global_timeout_millis: 400
});
instance_destroy();