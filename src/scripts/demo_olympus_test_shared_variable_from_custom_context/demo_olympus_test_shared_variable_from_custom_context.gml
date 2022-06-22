function demo_olympus_test_shared_variable_from_custom_context(){		
	not_explicitly_defined_variable = "goodbye";
	olympus_run("_shared_variable_from_custom_context", function(){
	  olympus_add_test("", function(){
		//Feather ignore GM1013 need to detect declared variables in the assigned custom context
	    show_debug_message(explicitly_shared_variable); 
		show_debug_message(not_explicitly_defined_variable); //Variable struct.not_explicitly_defined_variable not set before reading it. 
	  });
	}, {
		olympus_suite_options_context: {
			 explicitly_shared_variable : "hello"
		}
	})
}