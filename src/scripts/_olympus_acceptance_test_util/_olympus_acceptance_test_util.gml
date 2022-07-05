///@description Expects that the evaluation to be true
///@param {Any} evaluation
///@param {String} [additional_message=""]
function _olympus_acceptance_test_expect(evaluation, additional_message = "") {
	_olympus_acceptance_test_throw_result(true, evaluation, evaluation == true, additional_message);
}

///@description Expects that the actual value is equal to the expected value
///@param {Any} expected
///@param {Any} actual
///@param {String} [additional_message=""]
function _olympus_acceptance_test_expect_eq(expected, actual, additional_message = "") {
	_olympus_acceptance_test_throw_result(expected, actual, expected == actual, additional_message);
}

///@description Expects that the structs to equal. Can only compare non-nested structs.
///@param {Any} expected
///@param {Any} actual
///@param {String} [additional_message]
function _olympus_acceptance_test_expect_struct_eq(expected, actual){
		var keys = variable_struct_get_names(expected);
		for (var i = 0; i < array_length(keys); i++){
			var key = keys[i];
			var expected_value = expected[$ key];
			var actual_value = actual[$ key];
			if (is_string(expected_value) || is_numeric(expected_value) || is_bool(expected_value)){
				// Feather ignore GM1041 Need to detect the types inside the array
				_olympus_acceptance_test_expect_eq(expected_value, actual_value, key);
			}
			else{
				_olympus_console_log("Cannot compare non-string, non-boolean, non-number values: ", key);
			}
		}
}

///@description Throws an exception if the provided values do not match
///@param {any} expected
///@param {any} actual
///@param {Bool} matches
///@param {String} [additional_message]
function _olympus_acceptance_test_throw_result(expected, actual, matches, additional_message = "") {
	if additional_message != ""{
		additional_message += ": ";
	}
	if (!matches){
		var errorMessage = additional_message + "Expected [" + string(expected) + "] Actual [" + string(actual) + "]";
		throw({message: errorMessage, stacktrace: debug_get_callstack()});
	}
}

/// @arg obj
/// @arg [x=0
/// @arg y=0
/// @arg depth=0]
function _olympus_acceptance_test_instance_create() {
	var xx = 0;
	var yy = 0;
	var d = 0;
	if argument_count > 1{
		xx = argument[1];
	}
	if argument_count > 2{
		xx = argument[2];
	}
	if argument_count > 3{
		xx = argument[3];
	}
	return instance_create_depth(xx,yy,d, argument[0]);
}