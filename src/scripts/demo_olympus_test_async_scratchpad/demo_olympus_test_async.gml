function demo_olympus_test_async(){	
	//Define the logic to spawn the async mediator object and return its ID
	var mediator_spawning_logic = function(){
	    return instance_create_depth(0,0,0,demo_obj_http_mediator)
	}

	//Define your callback_to_inject
	var callback_to_inject = function(response_array){
	    var _async_load = response_array[0];
	    var http_status = _async_load[?"http_status"];
	    if (http_status == 200){
	        show_debug_message("Pinging Google succeeded.");
	    }
	    else{
	        throw("Expected 200. Got: " + string(http_status));
	    }    
	}

	//Register the test as an async test to the suite
	olympus_test_async("Test pinging Google", mediator_spawning_logic, callback_to_inject);
	//Run the suite
	olympus_run("My_Suite_Name");
}