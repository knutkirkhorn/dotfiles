# Tests

Tests for shell functions defined in the dotfiles.

## Running the tests

Run all tests from the repository root:

```sh
bash test.sh

# Or individually:

bash tests/test-open-repo.sh
bash tests/test-open-pr.sh
bash tests/test-open-gitlab-pr.sh
bash tests/test-base64decode.sh
bash tests/test-npm-security-hardening-ignore-scripts.sh
```

Or from inside the `tests` directory:

```sh
cd tests
bash test-open-repo.sh
bash test-open-pr.sh
bash test-open-gitlab-pr.sh
bash test-base64decode.sh
bash test-npm-security-hardening-ignore-scripts.sh
```

## Test files

| File                                            | Description                                                                                                                                                                                                                     |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `test-open-repo.sh`                             | Tests for the `open-repo` function in `.functions`. Verifies GitHub and GitLab remote URL normalization and rejects unsupported remote hosts                                                                                    |
| `test-open-pr.sh`                               | Tests for the `open-pr` function in `.functions`. Verifies GitHub pull request and GitLab merge request URLs are filtered to the current branch                                                                                 |
| `test-open-gitlab-pr.sh`                        | Tests for the `open-gitlab-pr` function in `.functions`. Verifies the constructed GitLab merge request URL for various scenarios (single/multiple commits, branch name formats, remote URL formats, different default branches) |
| `test-base64decode.sh`                          | Tests for the `base64decode` function in `.functions`. Verifies that a base64-encoded string is decoded into the expected plain-text output                                                                                     |
| `test-npm-security-hardening-ignore-scripts.sh` | Tests that `npm/npm-security-hardening.sh` prevents lifecycle scripts from running when installing `@lavamoat/preinstall-always-fail` with npm, pnpm, Yarn, and Bun                                                             |
