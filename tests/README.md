# Tests

Tests for shell functions defined in the dotfiles.

## Running the tests

Run all tests from the repository root:

```sh
bash tests/test-open-gitlab-pr.sh
bash tests/test-base64decode.sh
bash tests/test-npm-security-hardening-ignore-scripts.sh
```

Or from inside the `tests` directory:

```sh
cd tests
bash test-open-gitlab-pr.sh
bash test-base64decode.sh
bash test-npm-security-hardening-ignore-scripts.sh
```

## Test files

| File                                            | Description                                                                                                                                                                                                                     |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `test-open-gitlab-pr.sh`                        | Tests for the `open-gitlab-pr` function in `.functions`. Verifies the constructed GitLab merge request URL for various scenarios (single/multiple commits, branch name formats, remote URL formats, different default branches) |
| `test-base64decode.sh`                          | Tests for the `base64decode` function in `.functions`. Verifies that a base64-encoded string is decoded into the expected plain-text output                                                                                     |
| `test-npm-security-hardening-ignore-scripts.sh` | Tests that `npm/npm-security-hardening.sh` prevents lifecycle scripts from running when installing `@lavamoat/preinstall-always-fail` with npm, pnpm, Yarn, and Bun                                                             |
