#!/usr/bin/env bats

readonly FIXTURES="${BATS_TEST_DIRNAME}/Experiment"

@test "valid Experiment" {
  run kubeval --additional-schema-locations file://. "${FIXTURES}/valid.yaml"
  [[ $status -eq 0 ]]
  [[ $output = "PASS - ${FIXTURES}/valid.yaml contains a valid Experiment (test.test)" ]]
}

@test "invalid Experiment" {
  run kubeval --additional-schema-locations file://. "${FIXTURES}/invalid.yaml"
  [[ $status -eq 1 ]]
  [[ $output = "WARN - ${FIXTURES}/invalid.yaml contains an invalid Experiment (test.test) - name: name is required" ]]
}

@test "invalid Experiment in strict mode" {
  run kubeval --additional-schema-locations file://. --strict "${FIXTURES}/strict.yaml"
  [[ $status -eq 1 ]]
  [[ $output = "WARN - ${FIXTURES}/strict.yaml contains an invalid Experiment (test.test) - invalid-key: Additional property invalid-key is not allowed" ]]
}
