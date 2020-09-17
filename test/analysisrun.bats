#!/usr/bin/env bats

readonly FIXTURES="${BATS_TEST_DIRNAME}/analysisrun"

@test "valid AnalysisRun" {
  run kubeval --additional-schema-locations file://. "${FIXTURES}/valid.yaml"
  [[ $status -eq 0 ]]
  [[ $output = "PASS - ${FIXTURES}/valid.yaml contains a valid AnalysisRun (test.test)" ]]
}

@test "invalid AnalysisRun" {
  run kubeval --additional-schema-locations file://. "${FIXTURES}/invalid.yaml"
  [[ $status -eq 1 ]]
  [[ $output = "WARN - ${FIXTURES}/invalid.yaml contains an invalid AnalysisRun (test.test) - metrics: metrics is required" ]]
}

@test "invalid AnalysisRun in strict mode" {
  run kubeval --additional-schema-locations file://. --strict "${FIXTURES}/strict.yaml"
  [[ $status -eq 1 ]]
  [[ $output = "WARN - ${FIXTURES}/strict.yaml contains an invalid AnalysisRun (test.test) - invalid-key: Additional property invalid-key is not allowed" ]]
}
