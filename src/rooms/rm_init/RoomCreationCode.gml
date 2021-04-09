var starting_room = demo_olympus_rm;
switch os_get_config(){
	case "Olympus_dev":
	case "Olympus_acceptance_test":
	case "Olympus_bail":
		starting_room = _olympus_acceptance_test_rm;
		break;
	default:
		break;
}
room_goto(starting_room);