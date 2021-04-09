function demo_olympus_hooks(){	
	olympus_run("Accessing test data through hooks", function(){		
		#region tests
			xolympus_add_test("Unit test 1", function(){});
			olympus_add_test("Unit test 2", function(){ throw("Intentional failure")});
			olympus_add_test("Unit test 3", function(){});
		#endregion
		
		#region hooks
		olympus_add_hook_before_suite_start(function(suite_summary){
			show_debug_message("This suite contains the following tests:")
			var tests = suite_summary.tests;
			for (var i = 0; i < array_length(tests); i++){
				var this_test = tests[i];
				show_debug_message(olympus_get_test_name(this_test));
			}
		})

		olympus_add_hook_after_suite_finish(function(suite_summary){
			show_debug_message("Test completed.")
			var tallies = suite_summary.tallies;
			show_debug_message("total: " + string(tallies.total));
			show_debug_message("skipped: " + string(tallies.skipped));
			show_debug_message("crashed: " + string(tallies.crashed));
			show_debug_message("passed: " + string(tallies.passed));
			show_debug_message("failed: " + string(tallies.failed));
		})

		olympus_add_hook_before_each_test_start(function(unit_summary){
			show_debug_message("Start testing: " + olympus_get_test_name(unit_summary))
		})

		olympus_add_hook_after_each_test_finish(function(unit_summary){
			  if (olympus_get_test_status(unit_summary) != olympus_test_status_passed){
					show_debug_message(unit_summary.err);
			  }
		})
		#endregion
				
	},
	//Disable the default Olympus logging to not confuse with the logging from the hooks
	{olympus_suite_options_suppress_debug_logging: true}
	);
}