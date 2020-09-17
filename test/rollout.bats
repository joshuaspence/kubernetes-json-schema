#!/usr/bin/env bats

readonly FIXTURES="${BATS_TEST_DIRNAME}/Rollout"

@test "valid Rollout" {
  run kubeval --additional-schema-locations file://. "${FIXTURES}/valid.yaml"
  [[ $status -eq 0 ]]
  [[ $output = "PASS - ${FIXTURES}/valid.yaml contains a valid Rollout (test.test)" ]]
}

@test "invalid Rollout" {
  run kubeval --additional-schema-locations file://. "${FIXTURES}/invalid.yaml"
  [[ $status -eq 1 ]]
  [[ $output = "WARN - ${FIXTURES}/invalid.yaml contains an invalid Rollout (test.test) - selector: selector is required" ]]
}

@test "invalid Rollout in strict mode" {
  run kubeval --additional-schema-locations file://. --strict "${FIXTURES}/strict.yaml"
  [[ $status -eq 1 ]]
  [[ $output = "WARN - ${FIXTURES}/strict.yaml contains an invalid Rollout (test.test) - invalid-key: Additional property invalid-key is not allowed" ]]
}
