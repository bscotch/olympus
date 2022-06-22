function demo_olympus_multi_suite(){
	olympus_run("multi_suite", function(){
		olympus_add_async_test("async_stuff", function(){
			return instance_create_depth(0,0,0,demo_olympus_obj_http_mediator);
		})		
	}, {olympus_suite_options_allow_uncaught : true});
	
	olympus_run("suite2", function(){
		olympus_add_async_test("a2", function(){
			return instance_create_depth(0,0,0,demo_olympus_obj_http_mediator);
		})
	}, {olympus_suite_options_allow_uncaught : true})
}