function demo_olympus_test_async_with_awaiter(){	
	olympus_run(
		"async test demo with awaiter", 
		function(){
			olympus_add_async_test(
				"Test waiting until object creation", 							
				function(){
					instance_create_depth(0,0,0, demo_olympus_obj_spawner);
					//Feather ignore GM1041 Need to support multiple types
					return olympus_spawn_object_creation_awaiter(demo_olympus_obj_spawnling);			
				}
			);
			
			olympus_add_async_test(
				"Test waiting until object absence", 							
				function(){
					instance_create_depth(0,0,0, demo_olympus_obj_spawner);
					//Feather ignore GM1041 Need to support multiple types
					return olympus_spawn_object_absence_awaiter(demo_olympus_obj_spawnling);			
				}
			);				
	},	
	{olympus_suite_options_abandon_unfinished_record: true}
	);
}