function demo_olympus_test_async_scratchpad(){	
	out_side_context = "this";
	var function_to_add_tests = function() {
		//Define the logic to spawn the async mediator object and return its ID
		var mediator_spawning_logic = function(){	
			show_debug_message(out_side_context);
		    return instance_create_depth(0,0,0,demo_olympus_obj_http_mediator)
		}

		//Define your callback_to_inject
		var callback_to_inject = function(response_array){
			show_debug_message(out_side_context);
		    var _async_load = response_array[0];
		    var http_status = _async_load[?"http_status"];
		    if (http_status == 200){
		        audio_play_sound(demo_olympus_snd_coinpickup, 1, false);
		    }
		    else{
		        throw("Expected 200. Got: " + string(http_status));
		    }    
		}

		//Register the test as an async test to the suite
		olympus_add_async_test_with_user_feedback("Test pinging Google", "Did you hear a ping?",mediator_spawning_logic, callback_to_inject);
	}
	//Run the suite
	olympus_run("My_Suite_Name2", function_to_add_tests);
}