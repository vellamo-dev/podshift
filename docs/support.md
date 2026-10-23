# Support

PodShift is free software, maintained with limited time. This page sets the expectations so that reporting an issue stays useful without becoming a demand.

## What is welcome

- **Bug reports** against the official build. A clear report genuinely helps.
- **Feature ideas** that fit the project scope. See the scope test in [scope.md](./scope.md).

## Where to report

- **Bug reports and feature ideas**:  [GitHub Issues](https://github.com/vellamo-dev/podshift/issues).
- **Sponsored support**:  [vellamo.fyi](https://vellamo.fyi).

## What makes a report useful

- reproduce it on the official build, not a fork or a modified install;
- state the PodShift version and the server's operating system version;
- include the command, the expected result, and the actual result;
- include the relevant log lines: they are written with `logger -t podshift`, so find them with `journalctl -t podshift`.

## How issues are handled

1. A report that reproduces on the official build and fits the scope is triaged.
2. A fix happens when the change serves the project's goal.
3. An out-of-scope request is declined, not queued "for later".

## What is not promised

- **No obligation to fix.** A report is information, not a work order. There is no guarantee, no deadline, and no service level.
- **No priority by demand.** Issues are triaged and fixed in the order that serves the project's goal and its limited time, not in the order they are asked for.
- **No warranty.** PodShift is provided "as is", without warranty, as the AGPL license states.

## Security

Found a vulnerability? Don't report it publicly — PodShift hardens servers, so it matters. Report it privately via [vellamo.fyi](https://vellamo.fyi).

## Sponsored support

Need more than the free flow offers? That's welcome too.

If you want a fix or a feature on a timeline, or a change shaped to your own environment, sponsored support is the right channel. These requests are separate from the free flow: they happen only as a clear, agreed arrangement between you and a maintainer.

How it works:

- scope, timeline, and cost are agreed up front, in writing;
- work begins only after both sides have agreed;
- the result is always public open source, released under the same license and shared back; there are no private code changes.

In short: the free path is "report it, and it happens if and when it fits the project"; the sponsored path is "agree it, and it happens on a schedule". Both are welcome, just on different terms.
