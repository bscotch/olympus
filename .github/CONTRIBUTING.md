# Olympus Contributing Guideline

Thank you for being interested in contributing to Olympus!

## Reporting Issues/Requesting Features

Please check [existing issues](https://github.com/bscotch/olympus/issues) before creating new ones.

## Development Setup

You will need [GameMaker Studio 2](https://www.yoyogames.com/en/get) IDE version 2.3.2.556+, runtime 2.3.2.420+, and [set up the required SDKs](https://help.yoyogames.com/hc/en-us/articles/227860547-GMS2-Required-SDKs) for your target platforms.

After cloning the repo, open the `src/Olympus.yyp` project in the IDE to start development.

## Pull Request Guidelines

- PRs should be made against the `develop` branch

- Commit messages should follow the [commit message convention](https://www.conventionalcommits.org/en/v1.0.0/#summary) so that changelogs can be automatically generated.

- Ensure that the change passes the existing acceptance test by running the yyp project under the `Olympus_acceptance_test` config:
  - The acceptance test relies on [game_end()](https://manual-en.yoyogames.com/#t=GameMaker_Language%2FGML_Reference%2FGeneral_Game_Control%2Fgame_end.htm) to simulate a crash, so it can only be run on Windows, Linux and Mac.
  - Passing the acceptance test should result in the [show_message](https://manual-en.yoyogames.com/#t=GameMaker_Language%2FGML_Reference%2FDebugging%2Fshow_message.htm) prompt. The project should be run twice as the first run will exit with `game_end()`.
  - Failing the acceptance test will result in errors being thrown in the `olympus_add_hook_after_suite_finish` hook, where the unit test results are validated.
  - Add unit tests corresponding to the change in `_olympus_acceptance_test_starter`'s [User Event 0](../src/objects/_olympus_acceptance_test_starter/Other_10.gml) and ensure that the new unit tests and the acceptance test as a whole pass.
  - Unit test names should start with the initial `P_`, `F_`, `S_`, `C_` to indicate the expected `olympus_test_status` and the expected test result.

- If adding a new feature:
  - Add accompanying test case.
  - Provide a convincing reason to add this feature. Ideally, you should open a feature request issue first and have it approved before working on it.

- If fixing bug:
  - If you are resolving a reported issue, add `(fix #xxxx[,#xxxx])` (#xxxx is the issue id) in your PR title for a better release log, e.g. `update the lifecycle hooks (fix #3899)`.
  - Provide a detailed description of the bug in the PR.
  - Add appropriate test coverage if applicable.

## Project Structure

- `src`: contains the GameMaker Studio 2 project that hosts the Olympus resources. Opening the project in the IDE will give you a view of the different groups:
  - `Olympus`: contains the core library for Olympus to carry out its functions.
    - `_olympus_async_test_controller`: is an object that facilitates the serial spawning of async objects.
    - `_olympus_internal`: is a script that contains the internal logic of Olympus.
    - `olympus_external_api`: is the external-facing interface for end user.
  - `Acceptance_test`: contains the acceptance test for Olympus.
    - `_olympus_acceptance_test_helper_async*`: are objects used to test async logic.
    - `_olympus_acceptance_test_starter`: is an object that registers and runs all the acceptance test.
    - `_olympus_acceptance_test_util`: is a script that hosts utility functions.
  - `Demo`: Various demos and sample codes.
  - `Entry`: Entry point for the project.
  - The project has the following configs:
    - `Default`: will run the demos.
    - `Olympus_dev`: will run the acceptance test with the crash unit test and user feedback test skipped.
    - `Olympus_bail`: will run the acceptance test to test the `bail_on_fail_or_crash` option.
    - `Olympus_acceptance_test`: will run the acceptance test that is required for PR integration.
