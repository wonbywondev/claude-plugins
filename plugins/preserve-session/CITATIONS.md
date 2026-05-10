# External references — preserve-session

Independent acknowledgments and citations from upstream and community
discussions. Listed newest first.

These are public-record references; inclusion here does not imply
endorsement by Anthropic. preserve-session is a community-built plugin and
all citations below are from external developers participating in upstream
issue threads.

## Upstream issue threads

### anthropics/claude-code#40946 — CJK path collision

Issue tracking the lossy `[^a-zA-Z0-9-]` → `-` slug encoding that causes
non-ASCII (Korean / Japanese / Chinese / Cyrillic / Arabic / accented Latin)
project paths to collide on disk and in `/resume`. preserve-session ships
detection and data-safety guards for this case while the core fix is
pending upstream.

**2026-05-05 · @psh4607 (issue's original reporter, Dalpha)**
([comment link](https://github.com/anthropics/claude-code/issues/40946#issuecomment-4379649987))

> The community has already shipped a workaround plugin (@wonbywondev's
> `preserve-session` v1.3.1), but as the plugin author explicitly notes,
> the underlying slug algorithm in core is the only proper fix — the
> plugin can detect collisions and prevent destructive operations, but it
> cannot prevent two different paths from physically mixing `.jsonl` files
> in the same slug folder once Claude Code writes them.
>
> The two suggested fixes (URL-encode non-ASCII per RFC 3986, or preserve
> Unicode as-is on modern filesystems) are both small, contained changes
> to the path-to-slug function. Happy to test any candidate PR against my
> Korean-path setup.

Context: psh4607 confirmed the issue still reproduces on v2.1.126 and
flagged a separate finding — encoding split across the ecosystem, where
the same logical project ends up in two slug folders (one lossy from
Claude Code core, one Unicode-preserved from another tool).

**2026-04-23 · @ethan-beakmask (independent reproducer of #52513, closed as duplicate of #40946)**
([comment link](https://github.com/anthropics/claude-code/issues/40946#issuecomment-4307407669))

> Also acknowledging @wonbywondev's `preserve-session` plugin (v1.3.1,
> posted last week) as a meaningful community mitigation — the
> collision-aware cleanup and NFC/NFD doctor check are exactly the kind
> of defensive workarounds that shouldn't have to exist at the plugin
> layer. That a third-party plugin has had to ship explicit logic for
> "two paths collided — don't delete the data" is, in itself, evidence
> that this is a correctness bug the core needs to own.

Context: ethan-beakmask filed an independent reproduction of the same
underlying bug (CJK paths in zh_TW.UTF-8 locale) and consolidated their
report into #40946.
