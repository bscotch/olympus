//NOTE: Wrapper function for demo purpose
function demo_olympus_test_async(){	
	
	#region Async demo 
	olympus_run(
		//argument[0]: Suite name
		"async test demo", 
		
		//argument[1]: define a function that adds all the tests and hooks
		function(){

			//Name your unit test and add it to the suite as an async unit test
			olympus_add_async_test(

				//argument[0]: Test name
				"Test pinging Google", 			
				
				//argument[1]: Define a function that has the logic to spawn the async mediator object (the object that hosts the async event) and return its instance ID
				function(){
					return instance_create_depth(0,0,0,demo_olympus_obj_http_mediator)			
				},
				
				//argument[2]: Define a function that has the logic to be executed when the async logic resolves. Optionally, consume the response_array that contains all the variables that were passed to the resolution callback function.			
				function(argument){
					var async_load_from_mediator = argument[0];
					var http_status = async_load_from_mediator[?"http_status"];
					if (http_status == 200){
							show_debug_message("Pinging Google succeeded.");
					}
					else{
							throw("Expected 200. Got: " + string(http_status));
					}
				}
			);		
	});
	#endregion


}