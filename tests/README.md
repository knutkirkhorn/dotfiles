# Tests

Tests for shell functions defined in the dotfiles.

## Running the tests

Run all tests from the repository root:

```sh
bash tests/test-open-gitlab-pr.sh
```

Or from inside the `tests` directory:

```sh
cd tests
bash test-open-gitlab-pr.sh
```

## Test files

| File                     | Description                                                                                                                                                                                                                      |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `test-open-gitlab-pr.sh` | Tests for the `open-gitlab-pr` function in `.functions`. Verifies the constructed GitLab merge request URL for various scenarios (single/multiple commits, branch name formats, remote URL formats, different default branches). |
