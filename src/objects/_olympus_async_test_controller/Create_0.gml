#macro _olympus_user_feedback_confirm_message  "Pass"
_user_feedback_handle = noone;
_current_test = noone;

_function_to_call_on_test_start = global._olympus_default_hook_before_each_test_start;
_function_to_call_on_test_finish = global._olympus_default_hook_after_each_test_finish;
_interval_between_tests = 0;
_interval_between_tests_counter = 0;