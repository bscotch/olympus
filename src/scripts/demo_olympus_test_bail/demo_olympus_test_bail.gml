function demo_olympus_test_bail(){	
	olympus_run("Bail", function(){
		olympus_add_test("Failure", function(){ throw("Causing the rest of the unit tests to be skipped")});	
		olympus_add_test("Skipped by bail 1", function(){});
		olympus_add_test("Skipped by bail 2", function(){});
	}, {olympus_suite_options_bail_on_fail_or_crash: true})
}