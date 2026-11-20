# Security Policy

## Supported Versions

docs/security-policy

docs/explain-bloat-detector
main
omabloat is a small set of shell scripts, not a versioned application. Only the
latest `main` branch receives fixes.

| Version | Supported |
| --- | --- |
| `main` (latest) | :white_check_mark: |
| Older commits, tags and forks | :x: |

## Reporting a Vulnerability

Please do **not** open a public issue containing exploit details.

1. Preferred: use GitHub private vulnerability reporting —
   [Security tab → Report a vulnerability](https://github.com/TopGoy333/omabloat/security/advisories/new).
2. If that button is not available, open an issue titled
   "Security contact request" with **no** exploit details, and a private
   channel will be arranged.

Include: the script and commit, the exact command you ran, what you expected
versus what happened, and the potential impact. Never include secrets, keys or
tokens.

What to expect:

- Acknowledgement within about 7 days.
- A status update at least every 14 days while it is being assessed.
- If accepted: a fix on `main` and credit in the advisory (unless you prefer to
  remain anonymous).
- If declined: an explanation of why it is out of scope or not a vulnerability.

## Scope and safe-use notes

- `find-omarchy-bloat.sh` is **read-only**: it reports candidates and never
  removes packages, deletes files or changes services.
- The report may *suggest* privileged commands (for example
  `sudo pacman -Rns …`). Those are suggestions only — review them before
  running anything yourself.
- Companion cleanup tools live in
  [omababy](https://github.com/TopGoy333/omababy); they require explicit flags
  and confirmation, and protect core apps.
- This project publishes no secret keys. Do not paste credentials into issues,
  advisories or pull requests.
docs/security-policy

  
Use this section to tell people about which versions of your project are
currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 5.1.x   | :white_check_mark: |
| 5.0.x   | :x:                |
| 4.0.x   | :white_check_mark: |
| < 4.0   | :x:                |

## Reporting a Vulnerability

Use this section to tell people how to report a vulnerability.

Tell them where to go, how often they can expect to get an update on a
reported vulnerability, what to expect if the vulnerability is accepted or
declined, etc.
 main
main
