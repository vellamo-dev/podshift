# Forking

PodShift is free and open source (AGPL), and forking is allowed. This page sets the rules that keep a fork from becoming this project's problem.

## The one rule that matters

A fork is its own project. It carries its own name, its own distribution, its own bugs, and its own support. It must never present itself as PodShift, and it must never push its support burden back here.

## What a fork must do

- **Rebrand.** Change the name, package name, COPR project, and documentation so users cannot mistake the fork for the original. The names "PodShift", the official COPR repository, and the official documentation belong to this project only.
- **State the changes.** The AGPL license already requires this: preserve the original copyright and license notices, and clearly say what was changed.
- **Distribute independently.** A fork must build and publish its own RPM under its own COPR project or another channel. It must not reuse this project's COPR repository or package name.
- **Support itself.** The fork and its users are the fork's responsibility. There is no support, issue triage, or compatibility promise for forks.

## What this project supports

This project supports only what it ships through its own COPR repository. A bug report is in scope only if it reproduces on that official build. A report that reproduces only on a fork, or on a non-official build, is out of scope and will be closed.

## Forking done right

- fork the repository;
- rename the project and its package;
- publish under your own COPR project;
- keep the AGPL license and attribution;
- state your changes;
- point your users to your own issue tracker.

In short: fork freely, but fork at your own cost, and support follows only what this project ships.
