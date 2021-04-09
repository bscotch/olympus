function demo_olympus_test_shared_variable(){
	shared_variable_sum = 0;
	olympus_run("shared variables test", function(){
	  olympus_add_test("sum should be 1", function(){
	    shared_variable_sum ++;
	    show_debug_message(string(shared_variable_sum)); //1
	  });
  
	  olympus_add_test("sum should be 2", function(){
	    shared_variable_sum ++;
	    show_debug_message(string(shared_variable_sum)); //2
	  })
	})
}