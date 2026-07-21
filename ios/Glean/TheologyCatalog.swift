import Foundation
import GleanSelection

/// Curated, signed theological reflections for the feed’s context layer.
///
/// Rules (docs/04-moderation-design.md):
/// - Scripture stays primary and unmediated.
/// - Notes are signed (never anonymous institutional voice).
/// - Confidence is honest — personal reflection is labeled as such.
/// - Notes live with context, not on top of the clear focus verse.
/// - Prefer silence over a repeated generic blurb.
enum TheologyCatalog {

    /// Returns a note only when we have something specific or theme-shaped.
    /// Empty themes (offline random / untagged stories) → `nil` (no fortune-cookie spam).
    static func insight(
        chunkID: String,
        themes: [Theme],
        focusHint: String
    ) -> TheologyInsight? {
        if let specific = specificNotes[chunkID] {
            return specific
        }
        let base = chunkID.split(separator: ".").prefix(3).joined(separator: ".")
        if let specific = specificNotes[base] {
            return specific
        }
        // Story ids: story.noah.… — no generic filler
        if chunkID.hasPrefix("story.") || chunkID.hasPrefix("fallback.") {
            return nil
        }
        guard let primary = themes.first else { return nil }
        return themeFallback(primary: primary, focusHint: focusHint)
    }

    // MARK: - Passage-specific (short, careful, signed)

    private static let specificNotes: [String: TheologyInsight] = [
        "GEN.1.1-5": TheologyInsight(
            body: "Before anything else is said about you or the world, Scripture opens with God already at work — speaking light into what was formless. Creation is gift, not accident.",
            confidence: .widelyHeld
        ),
        "GEN.1.26-28": TheologyInsight(
            body: "Bearing God’s image is not a status ladder; it is a vocation of care — toward one another and toward the earth entrusted to us.",
            confidence: .widelyHeld
        ),
        "GEN.12.1-4": TheologyInsight(
            body: "Faith here is not a feeling first — it is trust that moves. Blessing was never meant to stop with Abram; it runs outward to the nations.",
            confidence: .widelyHeld
        ),
        "EXO.14.13-14": TheologyInsight(
            body: "Sometimes the most faithful act is to stop thrashing and stand still long enough to notice God is already fighting for you.",
            confidence: .oneReading
        ),
        "PSA.23.1-4": TheologyInsight(
            body: "The Shepherd does not promise no valley — only presence in it. ‘With me’ is the center of the comfort, not the absence of shadow.",
            confidence: .widelyHeld
        ),
        "PSA.23.1-6": TheologyInsight(
            body: "The Shepherd does not promise no valley — only presence in it. ‘With me’ is the center of the comfort, not the absence of shadow.",
            confidence: .widelyHeld
        ),
        "PSA.46.1-3": TheologyInsight(
            body: "Refuge is not escape from the world collapsing; it is a Person who holds when the mountains shake.",
            confidence: .widelyHeld
        ),
        "ISA.40.28-31": TheologyInsight(
            body: "Waiting on the Lord is not passive resignation. It is exchanging our spent strength for His — often after we admit we have none left.",
            confidence: .oneReading
        ),
        "ISA.53.4-6": TheologyInsight(
            body: "The wounded Servant bears what we cannot fix in ourselves. Christians read this as the shape of the cross: love that steps into our place.",
            confidence: .widelyHeld
        ),
        "JER.29.11-13": TheologyInsight(
            body: "Spoken first to exiles, not influencers. God’s ‘plans’ are covenant faithfulness in a hard place — not a blank check for every personal dream.",
            confidence: .oneReading
        ),
        "MIC.6.6-8": TheologyInsight(
            body: "Religion without justice, mercy, and humble walking is noise. God is not impressed by spectacle when the neighbor is still crushed.",
            confidence: .widelyHeld
        ),
        "MAT.5.3-10": TheologyInsight(
            body: "The Beatitudes bless the wrong people by the world’s scoreboard. The kingdom starts among the poor in spirit, the meek, the peacemakers.",
            confidence: .widelyHeld
        ),
        "MAT.6.9-13": TheologyInsight(
            body: "Jesus teaches us to pray as children, not as performers — daily bread, real forgiveness, and deliverance from evil, all in a few honest lines.",
            confidence: .widelyHeld
        ),
        "MAT.11.28-30": TheologyInsight(
            body: "Rest is not laziness here; it is relief from performing for God. His yoke fits because He walks it with you.",
            confidence: .widelyHeld
        ),
        "MAT.28.18-20": TheologyInsight(
            body: "The risen Christ claims all authority — then sends ordinary people to make disciples. Presence (‘I am with you’) is the fuel of the mission.",
            confidence: .widelyHeld
        ),
        "JHN.1.1-5": TheologyInsight(
            body: "The Word is not a later add-on to God; He is with God and is God — light that darkness cannot snuff out.",
            confidence: .widelyHeld
        ),
        "JHN.3.16-17": TheologyInsight(
            body: "Love is the motive, the Son is the gift, belief is the open hand, and life is the result. Judgment is not God’s eagerness — rescue is.",
            confidence: .widelyHeld
        ),
        "JHN.14.1-6": TheologyInsight(
            body: "Jesus does not point to a technique for getting home; He claims to be the way. Comfort for troubled hearts starts with who He is.",
            confidence: .widelyHeld
        ),
        "ROM.8.28-39": TheologyInsight(
            body: "‘All things’ does not mean all things are good — it means God is not finished with what evil meant for harm. Nothing can un-love you out of Christ.",
            confidence: .widelyHeld
        ),
        "ROM.12.1-2": TheologyInsight(
            body: "Worship is a body offered, not only a song sung. Renewed minds learn to recognize God’s will in ordinary choices.",
            confidence: .widelyHeld
        ),
        "1CO.13.4-8": TheologyInsight(
            body: "Love is described with verbs, not vibes. Patient and kind is harder — and holier — than impressive gifts without it.",
            confidence: .widelyHeld
        ),
        "EPH.2.8-10": TheologyInsight(
            body: "Saved by grace through faith, not by works — and yet created for good works. Gift first; then a life that fits the gift.",
            confidence: .widelyHeld
        ),
        "PHP.4.4-7": TheologyInsight(
            body: "Rejoicing and anxiety are both named honestly. Prayer with thanksgiving is how peace guards a mind that cannot guard itself.",
            confidence: .widelyHeld
        ),
        "1TH.5.16-18": TheologyInsight(
            body: "Short enough to memorize, large enough for a lifetime: joy, prayer, and gratitude as a way of breathing under God’s will.",
            confidence: .widelyHeld
        ),
        "HEB.11.1-3": TheologyInsight(
            body: "Faith is not make-believe; it is trust in a God who speaks worlds into being — and who keeps promises we have not yet seen.",
            confidence: .widelyHeld
        ),
        "1JN.4.7-12": TheologyInsight(
            body: "We love because He first loved us. If God is love, then loveless religion is a contradiction — no matter how correct our words.",
            confidence: .widelyHeld
        ),
        "REV.21.1-5": TheologyInsight(
            body: "The story ends with God making home among people — tears wiped, death undone, all things new. Hope has a destination, not only a mood.",
            confidence: .widelyHeld
        ),
    ]

    // MARK: - Theme fallbacks (only when a real theme is present)

    private static func themeFallback(primary: Theme, focusHint: String) -> TheologyInsight {
        let body: String
        switch primary {
        case .hope:
            body = "Hold this passage as a small light, not a slogan. Hope in Scripture is usually tied to God’s character more than our circumstances."
        case .faith:
            body = "Faith is less ‘trying harder to believe’ and more trusting the One who has already spoken. Let this re-anchor you there."
        case .love:
            body = "God’s love is not thin sentiment; it moves toward people. Ask where this invites you to receive love — or to give it away."
        case .wisdom:
            body = "Wisdom in the Bible is skill for living before God, not cleverness alone. Sit with this until it can shape one ordinary choice today."
        case .prayer:
            body = "Prayer is conversation with a Father who already knows. Let this teach you how to speak — and how to listen."
        case .repentance:
            body = "Repentance is a turning, not a wallowing. Grace makes room to come home without pretending nothing broke."
        case .suffering:
            body = "Scripture never treats pain as imaginary. This word does not erase the wound; it places God with you inside it."
        case .joy:
            body = "Biblical joy can coexist with tears. It is rooted in God, not in everything going well."
        case .justice:
            body = "God’s justice is not abstract theory — it defends the crushed. Let this search your life for who still needs a defender."
        case .creation:
            body = "The world is not ours to own carelessly. Creation language calls us to wonder, gratitude, and careful stewardship."
        case .kingdom:
            body = "The kingdom is God’s reign breaking in — often quietly, among the unlikely. Watch for its shape here."
        case .identity:
            body = "Before you are what you produce, you are addressed by God. Receive this as name and belonging, not as pressure."
        case .peace:
            body = "Peace here is shalom — wholeness — more than the absence of noise. Ask Christ to guard what your mind cannot."
        }
        _ = focusHint
        return TheologyInsight(body: body, confidence: .personal)
    }
}
