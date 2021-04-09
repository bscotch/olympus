function demo_olympus_test_shared_variable_from_custom_context(){		
	not_explicitly_defined_variable = "goodbye";
	olympus_run("shared variables from custom context test", function(){
	  olympus_add_test("", function(){
	    show_debug_message(explicitly_shared_variable); 
		show_debug_message(not_explicitly_defined_variable); //Variable struct.not_explicitly_defined_variable not set before reading it. 
	  });
	}, {
		olympus_suite_options_context: {
			 explicitly_shared_variable : "hello"
		}
	})
}