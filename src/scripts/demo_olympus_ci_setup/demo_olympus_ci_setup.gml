function demo_olympus_ci_setup(){
	olympus_run("Continuous integration setup", function(){		
		olympus_add_test("should pass", function(){});		
		olympus_add_async_test_with_user_feedback("should skip user feedback", "This prompt should not be shown!", function(){
			return instance_create(_olympus_acceptance_test_helper_async);
		});
		
		olympus_add_hook_after_suite_finish(function(){
			game_end();
		})
	},
	{
		olympus_suite_options_skip_user_feedback_tests: true,
		olympus_suite_options_ignore_if_completed: true
	}
	);
}