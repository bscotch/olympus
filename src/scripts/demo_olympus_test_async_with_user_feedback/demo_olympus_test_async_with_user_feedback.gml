function demo_olympus_test_async_with_user_feedback(){	
	//Name your test suite
	olympus_run("Async test with user feedback", function(){
		//Name your unit test and add it to the suite as an async unit test with user feedback
		olympus_add_async_test_with_user_feedback("Test sound rendering", 
			//Define the instruction to the user
			"Did you hear a ping?",			
			//Define the logic to spawn the async mediator object and return its instance ID
			function(){
				return instance_create_depth(0,0,0,demo_olympus_obj_sound_renderer)			
			}
		);		
	});	
}