/// @desc controller support and count down
var gp_num = gamepad_get_device_count();
for (var i = 0; i < gp_num; i++;){
	if gamepad_is_connected(i){ 
		if gamepad_button_check_pressed(i, gp_face1){
			_should_abandon_record = true;
		}
	}
}

_count_down_timer -= 1/room_speed
if _count_down_timer <= 0 {
	event_user(0);
}
