# Olympus

## Quick start

Compose your test suite:

```ts
//Name your test suite
olympus_run("my suite name", function () {
  //Add a unit test
  olympus_add_test(
    //Name your unit test
    "my unit test name",
    //Define the test assertion logic
    function () {
      var expected = "2";
      var actual = "1";
      if (actual != expected) {
        throw {
          message: "Expected: " + expected + ". Actual: " + actual,
          stacktrace: debug_get_callstack(),
        };
      }
    }
  );
});
```

[Code example](../../scripts/demo_olympus_quick_start/demo_olympus_quick_start.gml)

Test record is written to file in [the Save Area](https://manual-en.yoyogames.com/#t=Additional_Information%2FThe_File_System.htm) and a summary is shown in IDE output:

```sh
-------------------------
passed: 0
failed: 1
skipped: 0
crashed: 0
Record written to file as Olympus_records/my_suite_name.olympus.json
-------------------------
```

# Table of Contents

- [Olympus](#olympus)
- [Quick start](#quick-start)
- [Table of Contents](#table-of-contents)
- [Accessing Test Data with Hooks](#accessing-test-data-with-hooks)
  - [Suite Summary](#suite-summary)
    - [On Suite Start](#on-suite-start)
    - [On Suite Finish](#on-suite-finish)
  - [Unit Test Summary](#unit-test-summary)
    - [On Test Start](#on-test-start)
    - [On Test Finish](#on-test-finish)
- [Async Testing](#async-testing)
  - [Background](#background)
  - [Testing Async with Olympus](#testing-async-with-olympus)
  - [Testing Async with User Feedback](#testing-async-with-user-feedback)
- [Advanced Use Cases](#advanced-use-cases)
  - [Async Handler Function Name](#async-handler-function-name)
    - [Defining Through Test Options](#defining-through-test-options)
    - [Defining Through Suite Options](#defining-through-suite-options)
    - [Using olympus_test_resolve](#using-olympus_test_resolve)
  - [Recovering from Crashes](#recovering-from-crashes)
  - [Passing Variables Between Unit Tests](#passing-variables-between-unit-tests)
    - [Default Context](#default-context)
    - [Custom Context](#custom-context)
  - [Setting Up Dependency Chains](#setting-up-dependency-chains)
    - [Bail](#bail)
    - [Defining Dependency by Names](#defining-dependency-by-names)
    - [Creating a Dependency Chain](#creating-a-dependency-chain)
  - [Options](#options)
    - [Global Options](#global-options)
    - [Test Options](#test-options)
- [Caveat](#caveat)
- [Pull Request Process](#pull-request-process)

# Accessing Test Data with Hooks

[Code example](../../scripts/demo_olympus_hooks/demo_olympus_hooks.gml)

## Suite Summary

The test suite summary data is a GML struct with the following shape:

```jsonc
{
  "tallies": {
    //The tallies of unit tests results
    "skipped": 0,
    "crashed": 0,
    "total": 1,
    "passed": 0,
    "failed": 1
  },
  "name": "my_suite_name", //The suite name defined by `olympus_run(suite_name)`
  "tests": [
    //Array of unit test summaries. See [Unit Test Summary](#unit-test-summary)
  ]
}
```

You can access the most up to date version of this data through `olympus_get_current_suite_summary()`.
You can also access this data at the start and the finish of a test suite by `olympus_add_hook_before_suite_start()` and `olympus_add_hook_after_suite_finish()`.

### On Suite Start

You can set a function be executed right before a test suite starts with `olympus_add_hook_before_suite_start()`.

The entire suite summary is passed to the function, so you can do something like iterating through all the added tests and announcing their names:

```ts
olympus_add_hook_before_suite_start(function (suite_summary) {
  show_debug_message("This suite contains the following tests:");
  var tests = suite_summary.tests;
  for (var i = 0; i < array_length(tests); i++) {
    var this_test = tests[i];
    show_debug_message(this_test.name);
  }
});
```

### On Suite Finish

You can set a function be executed after a test suite finishes with `olympus_add_hook_after_suite_finish()`.

The entire suite summary is also passed to the function, so you can do something like annoucing the tallies of test results:

```ts
olympus_add_hook_after_suite_finish(function (suite_summary) {
  show_debug_message("Test completed.");
  var tallies = suite_summary.tallies;
  show_debug_message("total: " + tallies.total);
  show_debug_message("skipped: " + tallies.skipped);
  show_debug_message("crashed: " + tallies.crashed);
  show_debug_message("passed: " + tallies.passed);
  show_debug_message("failed: " + tallies.failed);
});
```

## Unit Test Summary

The unit test summary is the elements in the suite summary struct's `tests` array, which is also accessible by calling the `olympus_get_current_test_summaries()` function.

```jsonc
{
  "index": 0, //The unit test's index as the nth element of the suite's `tests` array
  "name": "my unit test name", //The unit test name defined by `olympus_add_*(name)`
  "status": "failed", //The unit test result
  "millis": 4, //The time span of the unit test in milliseconds
  "err": {
    //The error struct if unit the test did not pass
    "message": "Expected: 2. Actual: 1",
    "stacktrace": [
      "demo_olympus_quick_start:10",
      "_olympus_internal:485",
      "_olympus_async_test_controller_Step_0:18"
    ]
  }
}
```

You can access this data at the start and the finish of **each** unit test by `olympus_add_hook_before_each_test_start()` and `olympus_add_hook_after_each_test_finish()`.

Once you get a hold of the unit test summary struct, you can use the convenience function `olympus_get_test_status()` to access the `status` variable and `olympus_get_test_name()` to access the `name` variable.

### On Test Start

You can set a function be executed before each unit test starts with `olympus_add_hook_before_each_test_start()`.

The unit test summary is passed to the function, so you can do something like announcing the name of the unit test:

```ts
olympus_add_hook_before_each_test_start(function (unit_summary) {
  show_debug_message("Start testing: " + unit_summary.name);
});
```

### On Test Finish

You can set a function be executed after each unit test finishes with `olympus_add_hook_after_each_test_finish()`.

The unit test summary is also passed to the function, so you can do something like logging the error of the unit test if it did not pass:

```ts
olympus_add_hook_after_each_test_finish(function (unit_summary) {
  if (unit_summary.status != olympus_test_status.passed) {
    show_debug_message(unit_summary.err);
  }
});
```

# Async Testing

## Background

GML's [async events](https://manual-en.yoyogames.com/#t=The_Asset_Editors%2FObject_Properties%2FAsync_Events.htm) are mediated through objects. Taking [http_get()](https://manual-en.yoyogames.com/#t=GameMaker_Language%2FGML_Reference%2FAsynchronous_Functions%2FHTTP%2Fhttp_get.htm) as an example, we need some sort of mediator objects (let's call it `obj_http_mediator`) whose [Async HTTP Event](https://manual-en.yoyogames.com/#t=The_Asset_Editors%2FObject_Properties%2FAsync_Events%2FHTTP.htm) gives us the access to [async_load](https://manual-en.yoyogames.com/#t=GameMaker_Language%2FGML_Overview%2FVariables%2FBuiltin_Global_Variables%2Fasync_load.htm) when `http_get()` finally resolves:

```ts
///Pt 1
///obj_http_mediator Create Event
http_handle = http_get("https://google.com")

///obj_http_mediator Async HTTP Event
if async_load[?"id"] == http_handle{
  show_debug_message("http status is: " + string(async_load[?"http_status"]) )
}
```

With GML 2.3.1+, we can store script functions in variables and execute the functions by "calling" the variables:

```ts
///Pt 2
handler_function = function(the_async_load){
  show_debug_message("http status is: " + string(the_async_load[?"http_status"]) )
}
handler_function(async_load);
```

This language feature allows us to flexibly define what `obj_http_mediator` does with `async_load`. We start by storing the handler function into the instance variable `handler_function`:

```ts
///Pt 3
///Create Event
handler_function = function(){}
http_handle = http_get("https://google.com")

///Async HTTP Event
if async_load[?"id"] == http_handle{
  //Parse the async_load, such as reading async_load [? "result"];
  handler_function(async_load);
}
```

When we spawn `obj_http_mediator`, we can reassign the variable `handler_function` to a new function:

```ts
///Pt 4
with instance_create_depth(0,0,0,demo_obj_http_mediator){
  var new_handler_function = function(async_load_from_mediator){
    show_debug_message("http status is: "+string(async_load_from_mediator[?"http_status"]))
  }
  handler_function = new_handler_function;
}
```

## Testing Async with Olympus

[Async Testing code example](../../scripts/demo_olympus_test_async/demo_olympus_test_async.gml)

Once you set up an `obj_http_mediator` as shown above, you can test `http_get()` with Olympus by following these steps:

1. Wrap your async mediator object spawning logic in a function, and make sure that this function returns the mediator instance ID:

```ts
///Pt 1
var mediator_spawning_logic = function () {
  return instance_create_depth(0, 0, 0, obj_http_mediator);
};
```

2. Define your `new_handler_function` of how to handle the `async_load`. Note because Olympus packages the original `async_load` into the `argument` array, you have to retrieve it as the 0th element of the array:

```ts
///Pt 2
var new_handler_function = function(argument){
    var async_load_from_mediator = argument[0];
    var http_status = async_load_from_mediator[?"http_status"];
    if (http_status == 200){
        show_debug_message("Pinging Google succeeded.");
    }
    else{
        throw("Expected 200. Got: " + string(http_status));
    }
}
```

3. Let Olympus know the instance variable name of the handler function by constructing an options struct that has the variable name `resolution_callback_name`

```ts
///Pt 3
var options_to_register_handler_function_name = {
  resolution_callback_name: "handler_function",
};
```

4. Pass all these to `olympus_add_async_test()`:

```ts
///Pt 4
olympus_add_async_test(
  "Test Pinging Google",
  mediator_spawning_logic,
  new_handler_function,
  options_to_register_handler_function_name
);
```

5. Wrap all of these inside the `olympus_run()` block:

```ts
///Pt 5
olympus_run("My Suite Name", function(){
  //Define the logic to spawn the async mediator object and return its instance ID
  var mediator_spawning_logic = function(){
      return instance_create_depth(0,0,0,obj_http_mediator)
  }

  //Define your new_handler_function
  var new_handler_function = function(response_array){
      var async_load_from_mediator = response_array[0];
      var http_status = async_load_from_mediator[?"http_status"];
      if (http_status == 200){
          show_debug_message("Pinging Google succeeded.");
      }
      else{
          throw("Expected 200. Got: " + string(http_status));
      }
  }

  //Register the mediator object's instance variable name of the handler function
  var options_to_register_handler_function_name = {
    resolution_callback_name: "handler_function"
  }

  //Add the test as an async test to the suite
  olympus_add_async_test("Test Pinging Google", mediator_spawning_logic, new_handler_function, options_to_register_handler_function_name);
});
```

Olympus will run all your added async tests sequentially, wait for each one to resolve before moving on to the next one.

## Testing Async with User Feedback

[Code example](../../scripts/demo_olympus_test_async_with_user_feedback/demo_olympus_test_async_with_user_feedback.gml)

For tasks such as confirming graphics/audio rendering, it may be difficult to verify with assertion logic. You can use `olympus_add_async_test_with_user_feedback()` to render the effect, serve a text propmt to the user, and let them decide whether the test passed or not.

The prompt uses the cross-platform supported [get_string_async()](https://manual-en.yoyogames.com/#t=GameMaker_Language%2FGML_Reference%2FAsynchronous_Functions%2FDialog%2Fget_string_async.htm) method, which allows the user to pass or fail the test:

![prompt](https://i.imgur.com/T0rDdNl.png)

# Advanced Use Cases

Full API References is shown in the [olympus_external_api script resource](../../scripts/olympus_external_api/olympus_external_api.gml)

All the examples can be selected in the [demo room creation code](../../rooms/demo_olympus_rm/RoomCreationCode.gml) and run in the IDE with the `default` config.

## Async Handler Function Name

When adding async tests, Olympus needs to know the mediator object's instance variable name for the function that handles the async result. There are 3 ways to make the names known to Olympus:

### Defining Through Test Options

As shown in step 5 of [Testing Async with Olympus](##Testing-Async-with-Olympus), we passed an options struct with the variable name `resolution_callback_name` to `olympus_add_async_test` to inform Olympus what the instance variable name is for the handler function:

```ts
var options_to_register_handler_function_name = {
  resolution_callback_name: "handler_function"
}

olympus_add_async_test(..., options_to_register_handler_function_name);
```

### Defining Through Suite Options

[Code example](../../scripts/demo_olympus_test_async_with_custom_global_callback_name/demo_olympus_test_async_with_custom_global_callback_name.gml)

If all of your mediator objects use the same instance variable name for their async handler function, you can pass an options struct with the variable name `global_resolution_callback_name` to `olympus_run` to make that name known to Olympus:

```ts
var options_to_register_global_handler_function_name = {
  global_resolution_callback_name: "handler_function"
}

olympus_run(..., options_to_register_global_handler_function_name);
```

`global_resolution_callback_name` is set to `"callback"` by default, so if your mediator objects already use that name, you do not need to override the default.

**NOTE**: Each test's own `resolution_callback_name` option will take precedence to the suite's `global_resolution_callback_name` option.

### Using olympus_test_resolve

`olympus_test_resolve` is a syntactic sugar that saves the hassel of having to define the `resolution_callback_name` or `global_resolution_callback_name` options. Taking the earlier `obj_http_mediator` example in the [Background](##Background) section, instead of:

```ts
///Async HTTP Event
if async_load[?"id"] == http_handle{
  handler_function(async_load);
}
```

You can just have:

```ts
///Async HTTP Event
if async_load[?"id"] == http_handle{
  handler_function(async_load);
  //`handler_function` must not mutate the content of `async_load`
  olympus_test_resolve(async_load);
}
```

Behind the scenes, `olympus_test_resolve` calls a function whose name is already known to Olympus, so you don't have to define the `resolution_callback_name` or `global_resolution_callback_name` options.

**NOTE**: The best practice is to make a copy of `async_load` to be passed to `olympus_test_resolve` so that we don't have to worry about `olympus_test_resolve` and `handler_function` interfere with each other.

## Recovering from Crashes

[Code example](../../scripts/demo_olympus_crash_recover/demo_olympus_crash_recover.gml)

Because the runner [has to exit](https://manual-en.yoyogames.com/#t=GameMaker_Language%2FGML_Reference%2FDebugging%2Fexception_unhandled_handler.htm) after uncaught exception occurs, a suite of tests are not guaranteed to complete if a particular test unit throws an uncaught exception or silently crashes.

Olympus deals with this by keeping track of the last test unit status and writing the progress to file. Upon crash and reboot, this allows the runner to unstuck itself by identifying the last running unit as the crash cause and skipping it to complete the test suite.

To enable this behavior, create an options struct with the variable name `resume_previous_record` and set it to `true`, and pass it to `olympus_run()`:

```ts
var options_to_enable_crash_recovery = {
  resume_previous_record: true
}

olympus_run(..., options_to_enable_crash_recovery);
```

## Passing Variables Between Unit Tests

### Default Context

[Code example](../../scripts/demo_olympus_test_shared_variable/demo_olympus_test_shared_variable.gml)

Sometimes we may want to pass shared variables between unit tests. This is doable as all the unit tests within `olympus_run()` have access to the same scope by default, so you can do something like this:

```ts
shared_variable_sum = 0;
olympus_run("shared variables test", function () {
  olympus_add_test("sum should be 1", function () {
    shared_variable_sum++;
    show_debug_message(string(shared_variable_sum)); //1
  });

  olympus_add_test("sum should be 2", function () {
    shared_variable_sum++;
    show_debug_message(string(shared_variable_sum)); //2
  });
});
```

### Custom Context

[Code example](../../scripts/demo_olympus_test_shared_variable_from_custom_context/demo_olympus_test_shared_variable_from_custom_context.gml)

Alternatively, you can explicitly define what variables the tests should have access to by passing the options struct with the variable `olympus_suite_options_context` that points to a struct:

```ts
not_explicitly_defined_variable = "goodbye";
olympus_run(
  "shared variables from custom context test",
  function () {
    olympus_add_test("", function () {
      show_debug_message(explicitly_shared_variable);
      show_debug_message(not_explicitly_defined_variable); //Variable struct.not_explicitly_defined_variable not set before reading it.
    });
  },
  {
    olympus_suite_options_context: {
      explicitly_shared_variable: "hello",
    },
  }
);
```

## Setting Up Dependency Chains

Sometimes when an earlier unit test fails, we want to skip later unit tests. This can be done in 3 ways:

### Bail

[Code example](../../scripts/demo_olympus_test_bail/demo_olympus_test_bail.gml)

By passing an options struct as `{bail_on_fail_or_crash: true}` to `olympus_run()`, any unit test that fails or crashes will cause the rest of the unit tests to be skipped.

### Defining Dependency by Names

[Code example](../../scripts/demo_olympus_test_explicit_dependencies/demo_olympus_test_explicit_dependencies.gml)

By passing an options struct as `{dependency_names: ["test_name1", "test_name2"]}` to any of the `olympus_add*()` APIs, the unit test will be skipped if any of its dependencies did not pass.

### Creating a Dependency Chain

[Code example](../../scripts/demo_olympus_test_dependency_chain/demo_olympus_test_dependency_chain.gml)

Unit tests added between `olympus_test_dependency_chain_begin()` and `olympus_test_dependency_chain_end()` will be treated as sequentially dependent on each other, while tests outside of the chain are not affected.

## Caveat

- Olympus uses `exception_unhandled_handler()` to log uncaught errors. If you also uses `exception_unhandled_handler()`, make sure to re-assign your error handler function after the Olympus test suites conclude.
- All unit tests must have unique names to support the dependency chaining. If you named two tests with the same name, the runner should throw an error on boot.
