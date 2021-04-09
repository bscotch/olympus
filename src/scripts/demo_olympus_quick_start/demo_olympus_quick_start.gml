//NOTE: Wrapper function for demo purpose
function demo_olympus_quick_start(){
	
	//Name your test suite
	olympus_run("my suite name", function(){
		//Name your unit test and add it to the suite
		olympus_add_test("my unit test name", function(){
			//Define the test assertion logic 
			var expected = "2";
			var actual = "1";
			if (actual != expected){
				throw({
					message: "Expected: " + expected + ". Actual: " + actual, 
					stacktrace: debug_get_callstack()
				});
			}					
		});		
	});
}