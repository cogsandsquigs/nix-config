# Testing Conventions

- Write tests for all new features
- Maintain test coverage above 80%
    - Check if the project has a code-coverage tool
    - If a code-coverage tool is not available, estimate to the best of your ability
- Non-trivial logic gets one check that runs: test-file case that fails when the logic breaks.
  Non-trivial means a branch, a loop, a parser, or a money or security path. And always follow the
  testing table:

|                       | good input                      | bad input                        |
| --------------------- | ------------------------------- | -------------------------------- |
| **runtime**           | does it do the right thing?     | does it fail the way we said?    |
| **type** (only `.ts`) | does the valid program compile? | is the illegal program rejected? |

- **All end-user APIs, behaviors or features require a test in all four quadrants**, for both unit
  and integration tests. Internally, if something is only performing runtime- or type-actions, then
  only tests in said row(s) is necessary.
