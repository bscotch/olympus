function demo_olympus_test_async_with_custom_global_callback_name(){	
	olympus_run("async_with_custom_global_callback_name", function(){
		//Define the logic to spawn the async mediator object and return its ID
		var mediator_spawning_logic = function(){
		    return instance_create_depth(0,0,0,demo_olympus_obj_http_mediator_with_custom_callback_name)
		}

		//Define your callback_to_inject
		var new_handler_function = function(argument){
		    var async_load_from_mediator = argument[0];
		    var http_status = async_load_from_mediator[?"http_status"];
		    if (http_status == 200){
		        show_debug_message("Pinging Google succeeded.");
		    }
		    else{
		        throw("Expected 200. Got: " + string(http_status));
		    }    
		}

		//Register the test as an async test to the suite
		olympus_add_async_test("Test pinging Google", mediator_spawning_logic, new_handler_function);	
	},
	{olympus_suite_options_global_resolution_callback_name: "_callback"});
}