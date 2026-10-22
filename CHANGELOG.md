# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/2.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Entries before 1.3.0 were reconstructed from the Git history and
[GitHub Releases](https://github.com/omniauth/omniauth-oauth/releases).
Dates are when each version was published to RubyGems.org.

## [Unreleased]

## [1.3.0] - 2026-10-22

### Added

- RBS type signatures for the strategy, in `sig/`, checked with Steep.
- Support Ruby 4.0, which moved `CGI.parse`, used by the oauth gem, out of
  the standard library, by depending on the `cgi` gem.

### Changed

- Require omniauth 2.3.1 or later, so apps can set
  `OmniAuth.config.allowed_hosts` to reject forged hosts in callback URLs.
  See [GHSA-m27g-v28p-f9fx](https://github.com/omniauth/omniauth/security/advisories/GHSA-m27g-v28p-f9fx).
- Require Ruby 2.5 or later.
- The gem includes only `lib`, `sig`, the license, and the README, not the
  specs, CI workflows, or tool configs.

## [1.2.1] - 2024-08-27

### Added

- Support Rack 3.

## [1.2.0] - 2021-01-28

### Changed

- Allow omniauth 2, to mitigate CVE-2015-9284, by relaxing the omniauth
  requirement to `>= 1.0, < 3`.

## [1.1.0] - 2015-04-22

### Removed

- The unused `require "multi_json"`, which wasn't a declared dependency.
- Development dependencies from the gemspec, and the beta note in the
  README.

## [1.0.1] - 2012-03-02

### Added

- A `request_params` option, passed to `get_request_token`.

## [1.0.0] - 2011-11-02

### Added

- Initial release, extracted from the `oa-oauth` gem for OmniAuth 1.0.

[Unreleased]: https://github.com/omniauth/omniauth-oauth/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/omniauth/omniauth-oauth/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/omniauth/omniauth-oauth/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/omniauth/omniauth-oauth/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/omniauth/omniauth-oauth/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/omniauth/omniauth-oauth/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/omniauth/omniauth-oauth/releases/tag/v1.0.0
