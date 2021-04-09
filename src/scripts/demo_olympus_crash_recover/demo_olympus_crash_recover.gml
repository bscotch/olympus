function demo_olympus_crash_recover(){
	olympus_run("crash recover", function(){		
		olympus_add_test("should pass 1", function(){});		
		olympus_add_async_test("Simulating a crash that causes the runner to exit", function(){
			game_end();
		});
		olympus_add_test("should pass 2", function(){});		
		});
}