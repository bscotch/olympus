
function demo_olympus_default_hooks(){	

	olympus_set_default_test_start_code_injection(function() {
		show_debug_message("test is starting");
	});

	olympus_set_default_test_end_code_injection(function() {
		 // this is still inside the test execution try/catch
		 throw("Intentional failure");
		 show_debug_message("This will not show!!");
	});
	
	olympus_set_default_hook_after_each_test_finish(function() {
		 show_debug_message("This message will show on pass/skip/failed!!");
		 // A throw here will break Olympus execution.
		 // throw("Intentional failure");
	});
	
	olympus_run("Accessing test data through hooks", function(){		
		#region tests
			xolympus_add_test("Unit test 1", function(){});
			olympus_add_test("Unit test 2", function(){ throw("Intentional failure")});
			olympus_add_test("Unit test 3", function(){});
		#endregion
		
	},
	//Disable the default Olympus logging to not confuse with the logging from the hooks
	{
		olympus_suite_options_suppress_debug_logging: true
	});
}