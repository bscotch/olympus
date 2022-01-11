function demo_olympus_test_async_awaiter(){
	//The awaiter function allows you to add a async test that wait to resolve until certain condition is met
	global.awaiter_counter = 0;	
	olympus_run("Awaiter_demo", function(){		
		#region waiting for a value to change
		olympus_add_test("before_waiting", function(){
			show_debug_message("awaiter_counter:"  + string(global.awaiter_counter));
		})
				
		olympus_add_async_test("awaiter_test", 
			function(){
				var awaiter_instance = olympus_spawn_awaiter(function(){
					global.awaiter_counter ++;
					return global.awaiter_counter == 5;
				})			
				return awaiter_instance;
			}
		)
		
		olympus_add_test("after_waiting", function(){
			show_debug_message("awaiter_counter:"  + string(global.awaiter_counter));
		})
		#endregion
		
		#region waiting for an object to spawn
		olympus_add_test("before_waiting_object_creation", function(){
			show_debug_message("Exists:"  + string(instance_exists(demo_olympus_obj_sound_renderer)));
		})
				
		olympus_add_async_test("awaiter_object_creation_test", 
			function(){
				instance_create_depth(0,0,0, demo_olympus_obj_delayed_object_spawner);
				var awaiter_instance = olympus_spawn_object_creation_awaiter(demo_olympus_obj_sound_renderer);			
				return awaiter_instance;
			}
		)
		
		olympus_add_test("after_waiting_object_creation", function(){
			show_debug_message("Exists:"  + string(instance_exists(demo_olympus_obj_sound_renderer)));
		})
		#endregion
		
		#region waiting for an object to be absent
		olympus_add_test("before_waiting_object_absence", function(){			
			instance_create_depth(0,0,0, demo_olympus_obj_delayed_object_spawner);
			show_debug_message("Exists:"  + string(instance_exists(demo_olympus_obj_delayed_object_spawner)));
		})
				
		olympus_add_async_test("awaiter_object_absence_test", 
			function(){
				var awaiter_instance = olympus_spawn_object_absence_awaiter(demo_olympus_obj_delayed_object_spawner);			
				return awaiter_instance;
			}
		)
		
		olympus_add_test("after_waiting_object_absence", function(){
			show_debug_message("Exists:"  + string(instance_exists(demo_olympus_obj_delayed_object_spawner)));
		})
		#endregion			
	});
}