function demo_olympus_test_dependency_chain(){	
	olympus_run("Dependency chain", function(){		
		olympus_test_dependency_chain_begin();
		olympus_add_test("F_chain_1", function(){ throw("Causing the rest of the chain to be skipped")});	
		olympus_add_test("S_chain_2", function(){});
		olympus_add_test("S_chain_3", function(){});
		olympus_test_dependency_chain_end();
		olympus_add_test("P_chain_4", function(){ _olympus_console_log("Outside of the chain, so should pass")});
		olympus_test_dependency_chain_begin();
		olympus_add_test("P_chain_5", function(){_olympus_console_log("Should all pass")});	
		olympus_add_test("P_chain_6", function(){_olympus_console_log("Should all pass")});
		olympus_add_test("P_chain_7", function(){_olympus_console_log("Should all pass")});
		olympus_test_dependency_chain_end();	
	})
}