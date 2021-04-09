function demo_olympus_test_explicit_dependencies(){	
	olympus_run("Bail", function(){
		olympus_add_test("Failure", function(){ throw("Causing the rest of the unit tests to be skipped")});	
		olympus_add_test("Skipped by dependency failure 1", function(){}, {olympus_test_options_dependency_names: "Failure"});		
		olympus_add_test("Unaffected", function(){});
		olympus_add_test("Skipped by dependency failure 2", function(){}, {olympus_test_options_dependency_names: ["Unaffected", "Failure"]});	
	})
}