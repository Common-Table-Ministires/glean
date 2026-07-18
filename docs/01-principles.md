# Principles

These are decision rules, not preferences. When a feature request or design choice is ambiguous, check it against this list before checking it against anything else. If a proposal conflicts with one of these, the proposal changes, not the principle, unless the principle itself is being deliberately revisited (write an ADR in [/decisions](../decisions) if that happens).

## Offline-first, non-negotiable

Full text lives on the device. The app works with no signal: on a plane, in a hospital waiting room, in a basement. This is not "offline-capable as a nice-to-have," it is the baseline assumption every other feature is built on top of. Anything that requires a network round trip to show a passage (a live-fetched translation, a server-rendered feed) is disqualified by this principle alone, regardless of its other merits.

**Why:** the moment someone needs Scripture most is disproportionately likely to be a moment they don't have signal. A formation tool that only works with connectivity has quietly become a convenience tool instead.

## No account required to read

Reading requires nothing: no signup, no login, no email capture. An account exists only if someone wants to comment, and even then it should ask for the minimum needed to attribute a comment and moderate abuse, nothing more.

**Why:** an account wall in front of Scripture reproduces exactly the gatekeeping this project exists to reject, even if the account itself is free.

## No gamification

No streaks, no badges, no completion percentage, no "you're behind" messaging. At most one gentle, optional, dismissible daily nudge, never framed as guilt ("you missed yesterday") and never framed as achievement ("5 day streak!").

**Why:** streaks and completion states are attention-economy mechanics. They work by creating anxiety about breaking a chain, which is the opposite of formation through unhurried repeated exposure. Borrowing the scroll habit is fine; borrowing the anxiety mechanics that usually ride along with it is not.

## No ads, ever, not "for now"

There is no version of this roadmap where ads get added later to fund something. If the ministry can't sustain hosting and maintenance through giving, the answer is to reduce scope, not to sell attention inside the text.

**Why:** stated in the vision doc directly: this project exists because other Bible software nickel-and-dimes people. An ad is a smaller, slower version of the same thing.

## Fast cold start

Open, read something, close. Target under two seconds from tap to a readable passage on screen, on a mid-range device.

**Why:** the whole mechanic depends on the app being lower-friction than picking up the phone habitually already is. A slow cold start is a tax on every single session, and it compounds against exactly the muscle-memory behavior the mechanic is trying to borrow.

## Accessible by default, not as a retrofit

Large type support, screen reader clean, high contrast. Built in from the first screen, not added after launch.

**Why:** a formation tool that quietly excludes people with low vision or who rely on assistive technology has failed at its actual purpose for exactly the people who may need unhurried, low-friction access to Scripture the most.

## Translation must be public domain or explicitly licensed for free redistribution

Hard blocker, not a preference. See [03-translation-research.md](03-translation-research.md) for the specific candidates and why most modern translations are excluded by this rule.

**Why:** a licensing dependency on a commercial publisher is a single point of failure for a project meant to run for a decade under a small nonprofit. It also directly conflicts with "free, forever, asks nothing" the moment a license fee or usage cap enters the picture.

## Design for a solo maintainer over ten years, not a team over one year

When a design choice trades ongoing maintenance burden for a nicer feature, the maintenance burden wins by default. This applies especially to anything with a moderation queue, a content pipeline, or a recurring editorial task (see [04-moderation-design.md](04-moderation-design.md) once it exists).

**Why:** stated directly by the person building this: optimize for what a solo maintainer with a family, a ministry, and a welding program can actually sustain, not for what looks impressive in year one and becomes an abandoned feature by year three.

## Boring and durable beats clever

Prefer well-understood, long-lived technology choices over ones that are more elegant but riskier to maintain solo, harder to hire help for later, or more likely to be abandoned upstream.

**Why:** a ten-year project can't afford to be re-platformed every time a clever dependency goes unmaintained. This principle governs the stack discussion directly.
