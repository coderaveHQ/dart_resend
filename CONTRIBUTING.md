# Contributing to dart_resend

Thank you for helping improve the community Dart SDK for Resend.

All contributors must follow the [Code of Conduct](code_of_conduct.md).

## Before opening a change

Open an issue for bugs, new endpoints, response-shape changes, or larger design
work. Include the relevant Resend documentation, the expected wire request and
response, reproduction steps, and the installed Dart and package versions.

Never include real API keys, webhook signing secrets, OAuth tokens, recipient
data, or unredacted API responses in issues, fixtures, commits, or logs.

## Development setup

Use a Dart SDK compatible with the range in `pubspec.yaml`, then run:

```console
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```

Run tests with coverage before submitting:

```console
dart test --coverage=coverage
dart run coverage:format_coverage \
  --packages=.dart_tool/package_config.json \
  --report-on=lib \
  --in=coverage \
  --lcov \
  --out=coverage/lcov.info
```

The package maintains 100% line coverage for `lib/`. New behavior, validation
branches, failures, response fields, and forward-compatibility paths all need
tests. Do not exclude production code merely to satisfy the threshold.

## Package design expectations

- Expose public functionality through `lib/dart_resend.dart`; consumers must
  not need `src/` imports.
- Model wire payloads with immutable typed request and response objects.
- Validate deterministic client-side constraints before transport calls.
- Preserve undocumented response fields through `ResendModel.json` and keep
  evolving server statuses forward-compatible where possible.
- Use cursor pagination and `ResendResponse<T>` consistently.
- Throw the established `ResendException` subtype for transport and decoding
  failures.
- Keep API keys and other credentials out of distributed-client examples.
- Match current official Resend documentation and verify endpoint behavior
  against the upstream API or schema.

Breaking changes are acceptable when they materially improve the package, but
must include migration notes and a semver-appropriate version change.

## Documentation and examples

Every new operation or meaningful request variant must include:

- public API documentation;
- tests, including failure branches;
- a compileable, public-entrypoint-only example in `example/`;
- a direct link from the README feature index; and
- a changelog entry.

Format examples with `dart format example` and verify them with
`dart analyze example`.

## Pull requests

Keep pull requests focused and explain API or wire-format decisions. Use
conventional commit messages with a subject shorter than 100 characters. Before
requesting review, ensure formatting, static analysis, tests, coverage, docs,
and examples all pass locally.

## Legal

All contributions to this repository are made under the
[MIT License](https://opensource.org/licenses/MIT).

### What this means practically

If you make a pull request, the contribution is licensed under MIT. Once merged,
it is also made available under the project's GPLv3 license as part of
`dart_resend`. Your original MIT license still applies to your contribution.
The MIT notice below must be retained.

### Why do it this way

This allows the project to change the `dart_resend` license in the future
without requiring every contributor to sign a CLA or transfer copyright.

### MIT License for contributions

Copyright 2022 Code Contributor (whoever you are)

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
