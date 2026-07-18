# Moderation design

Status: first pass, for reaction. Starting assumption per the original brief: moderation capacity is near zero, a solo maintainer with a family, a ministry, and a welding program. Every option below is evaluated against that constraint first, engagement or feature richness second.

## A tension worth surfacing before anything else

The original vision text says people can add "thoughts or cited theological insight," explicitly both, not cited insight only. That matters: any design that requires a citation to post at all is stricter than what was actually asked for, and would quietly exclude genuine personal reflection in favor of only scholarly-style input. Flagging this now so it doesn't get designed away by accident later. The options below distinguish requiring citations from privileging them, on purpose.

## Four shapes the feature could take, from least to most moderation exposure

**1. Private notes only, no shared surface at all.** A reader can write something attached to a passage, visible only to them, no account required, stored the same way local reading state is. This is the honest floor if moderation capacity really is zero: there is nothing to moderate because nothing is shared. It does not deliver a commons or "cited theological insight" as a community feature, it delivers a journal. Worth having regardless of what else gets built, since it's cheap and it's genuinely useful on its own.

**2. Curated annotations, ministry-authored, no user posting.** Common Table Ministries (or a small invited set of contributors) writes citations and short insights attached to specific passages, shown to every reader, nobody else can post. This removes the moderation problem structurally, there's no open submission surface, while still delivering "cited theological insight" as promised. The cost is authorship, not moderation: someone has to write this content, and it's ongoing work, similar in shape to the book-intro authorship cost named in `content-model.md`. Bounded and schedulable, unlike an open comment queue that can grow faster than one person can keep up with.

**2a. Authorial honesty: not letting personal reflection wear institutional authority.** If curated annotations include the maintainer's own theological reflection, and not only cross-tradition citations, there's a real risk the app quietly presents one person's still-forming thinking as the app's official, neutral teaching. That risk is worth naming directly rather than assuming careful writing alone solves it, because the medium (an unsigned note attached to the text, styled like a study-Bible footnote) carries institutional authority regardless of how tentative the actual content is. Concrete mitigations:
   - Every curated note is signed with its actual source (a name, or "patristic," or a named tradition), never presented as an anonymous, institutional voice.
   - Every curated note carries an honest confidence tag: widely held across Christian tradition, one reading among several (disputed), or personal reflection, unresolved. A genuinely open question for the author, perseverance is the example on the table right now, gets tagged as open, not quietly resolved just because it made it into the app.
   - Curated notes never interleave with the Scripture text itself. The text is always the primary, unmediated thing on screen; a note lives in a clearly separate, collapsed-by-default layer the reader deliberately opens, so reading the passage alone never requires passing through someone's commentary on it first.
   - Plurality is a deliberate goal, not a nice-to-have: citations from multiple traditions sitting next to each other make it visibly true that the app is offering "one voice among several," which protects readers from mistaking one person's view for consensus, and protects the maintainer from a single, still-forming personal position getting scaled to everyone who opens the app.
   - A short, plainly worded About-page statement, read once and meant: these are reflections, not doctrine; read the text first; weigh these as one perspective among others, not the final word.

**3. User-submitted, structurally constrained to reduce brawl risk.** Real community input, but shaped mechanically rather than policed manually:
   - No reply threading. Passage-level notes only, flat, no back-and-forth chains. Most escalation happens in reply chains; removing them removes most of the mechanism, not just the visibility of it.
   - Rate limits (a small number of posts per person per day). Cheap, discourages the kind of repeated argument that turns into a brawl, doesn't require anyone watching in real time.
   - Citations privileged, not required: a comment can optionally reference a source (a commentator, a creed, a cross-reference), and cited comments sort above uncited ones or carry a visual marker, but plain reflection is still allowed, consistent with what the vision doc actually asked for.
   - Report button plus auto-hide after a small number of reports, pending a periodic (not real-time) review pass. This is the single highest-leverage low-effort lever: it turns moderation from "someone has to be watching" into "someone reviews a short queue on their own schedule."

**4. Global, unconstrained, open comment section.** Standard social-media shape. Not recommended at any point on this roadmap; it's the shape most likely to produce exactly the doctrinal brawl the brief is worried about, and it assumes exactly the moderation capacity that's been stated not to exist.

## Visibility: global vs. opt-in

Independent of which posting model above gets chosen, whether comments are visible by default matters a lot for exposure.

**Global by default** (everyone sees community comments on every passage automatically) maximizes reach and reads as "part of the app" rather than a bolted-on feature, but it also means every reader is exposed to whatever's there, including anything that hasn't been reviewed yet.

**Opt-in, off by default** (a reader has to explicitly toggle on "show community reflections") shrinks the blast radius by construction: most readers never see the surface at all, so a bad-faith post that slips through briefly reaches a much smaller audience before it's caught. The friction of opting in also tends to filter out drive-by low-effort posting in favor of people who actually care enough to look for the feature, which correlates with lower conflict in other small communities that use the same pattern.

**Recommended shape, combining the above:** curated annotations (option 2, signed and confidence-tagged per 2a) visible to everyone by default, since that's zero-moderation-risk and directly delivers "cited theological insight," honestly labeled. Community comments (option 3, structurally constrained) available only behind an explicit opt-in toggle, clearly visually distinguished from the curated layer so a reader always knows what's official versus informal, and what's settled versus one person's still-open question. This lets the feature grow into option 3 gradually and only for the audience that actively wants it, without ever exposing the default reading experience, the actual core product, to unmoderated content, and without ever presenting the maintainer's personal theology as more settled than it actually is.

## Accounts, minimally

Per `01-principles.md`, an account exists only to comment, not to read. Concretely: whatever the account is (email, or a lighter identifier), it should exist to attribute a post and to apply rate limits and report-based hiding per-person, not to build a profile or social graph. No follower counts, no public posting history page, nothing that turns commenting into its own status game, that would reintroduce exactly the attention-economy mechanics principle 3 rejects.

## What sustainable actually means here, stated plainly

Sustainable does not mean "moderated well." It means the maintainer can walk away for two weeks and come back to a queue that's still a short list, not an unmanageable backlog, because the volume-limiting mechanisms (opt-in visibility, rate limits, no threading) capped the size of the surface in the first place. A written, simple, publicly posted comment policy (something like: cite a source or share how this affected you personally, don't relitigate denominational disputes here) gives a fast, defensible bar to apply during that periodic review, rather than requiring a fresh judgment call every time.

The other half of sustainable: an explicit, no-shame kill switch. If the comment surface ever becomes more burden than it's worth, turning it off entirely should be a normal, available decision, not a failure state. A feature that quietly gets abandoned half-moderated is worse than a feature that gets deliberately turned off.

## Open questions this doc leaves for you to react to

- Is the phased shape right (curated first, user comments later behind opt-in), or does user-submitted input need to exist from day one for this to feel like a real commons rather than a broadcast?
- Who writes the curated annotations if it's not just you: is there a trusted-contributor model worth designing now, or is that premature before there's any usage to justify it?
- Is a rate limit plus report-and-hide enough, or is pre-approval (nothing visible until reviewed) worth the throughput cost for the first few months specifically, while volume is low enough that the queue can't get away from you?
- Does the account for commenting need real identity (email verification) or is a lighter-weight, easier-to-abuse identifier an acceptable tradeoff for keeping the barrier to participation low?
- Is the three-tier confidence tag (widely held, disputed, personal reflection) the right taxonomy, or does it need a fourth category, or a lighter touch than a visible tag on every single note?
