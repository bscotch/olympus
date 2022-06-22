test_starter_instance_variable = "test_starter_instance_variable";
test_starter_instance_variable_to_be_replaced_by_custom_context = "test_starter_instance_variable_to_be_replaced_by_custom_context"

_should_abandon_record = false;
_count_down_timer = 0;
if os_get_config() == "Olympus_dev" 
//|| debug_mode
{
	_should_abandon_record = true;
	event_user(0);
}
