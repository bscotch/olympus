test_starter_instance_variable = "test_starter_instance_variable";

_should_abandon_record = false;
_count_down_timer = 0;
if os_get_config() == "Olympus_dev"{
	_should_abandon_record = true;
	event_user(0);
}
