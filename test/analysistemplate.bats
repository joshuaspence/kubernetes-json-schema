#!/usr/bin/env bats

readonly FIXTURES="${BATS_TEST_DIRNAME}/analysistemplate"

@test "valid AnalysisTemplate" {
  run kubeval --additional-schema-locations file://. "${FIXTURES}/valid.yaml"
  [[ $status -eq 0 ]]
  [[ $output = "PASS - ${FIXTURES}/valid.yaml contains a valid AnalysisTemplate (test.test)" ]]
}

@test "invalid AnalysisTemplate" {
  run kubeval --additional-schema-locations file://. "${FIXTURES}/invalid.yaml"
  [[ $status -eq 1 ]]
  [[ $output = "WARN - ${FIXTURES}/invalid.yaml contains an invalid AnalysisTemplate (test.test) - metrics: metrics is required" ]]
}

@test "invalid AnalysisTemplate in strict mode" {
  run kubeval --additional-schema-locations file://. --strict "${FIXTURES}/strict.yaml"
  [[ $status -eq 1 ]]
  [[ $output = "WARN - ${FIXTURES}/strict.yaml contains an invalid AnalysisTemplate (test.test) - invalid-key: Additional property invalid-key is not allowed" ]]
}
