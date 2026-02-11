import Foundation

struct WellnessTip: Identifiable, Sendable {
    let id: String
    let text: String
    let category: TipCategory
    let conditions: [TipCondition]
}

enum TipCategory: String, Sendable {
    case breathing, posture, hydration, breaks, mindset, social, movement, nutrition

    var displayName: String {
        switch self {
        case .breathing: return "Breathing"
        case .posture: return "Posture"
        case .hydration: return "Hydration"
        case .breaks: return "Breaks"
        case .mindset: return "Mindset"
        case .social: return "Social"
        case .movement: return "Movement"
        case .nutrition: return "Nutrition"
        }
    }
}

enum TipCondition: Sendable {
    case weather(InnerWeather)           // show when specific weather
    case timeOfDay(ClosedRange<Int>)     // hour range (e.g., 9...12 for morning)
    case afterPractice                    // show after completing a practice
    case consecutiveClear(Int)           // after N consecutive clear readings
    case stormy                          // during stormy weather
    case evening                         // after 16:00
    case morning                         // before 11:00
    case any                             // always eligible
}

struct TipService: Sendable {

    /// Get a contextual tip based on current state
    func tipFor(
        weather: InnerWeather,
        hour: Int = Calendar.current.component(.hour, from: Date()),
        afterPractice: Bool = false,
        consecutiveClearCount: Int = 0
    ) -> WellnessTip {
        let eligible = Self.tips.filter { tip in
            tip.conditions.contains { condition in
                switch condition {
                case .weather(let w): return w == weather
                case .timeOfDay(let range): return range.contains(hour)
                case .afterPractice: return afterPractice
                case .consecutiveClear(let n): return consecutiveClearCount >= n
                case .stormy: return weather == .stormy
                case .evening: return hour >= 16
                case .morning: return hour < 11
                case .any: return true
                }
            }
        }
        return eligible.randomElement() ?? Self.tips[0]
    }

    // MARK: - Tip Catalog (96 tips)

    static let tips: [WellnessTip] = [
        // BREATHING (12)
        WellnessTip(id: "b1", text: "Try breathing in for 4, out for 6. Longer exhales activate your calm response.", category: .breathing, conditions: [.weather(.cloudy), .any]),
        WellnessTip(id: "b2", text: "Your breath is the only autonomic function you can consciously control. Use it.", category: .breathing, conditions: [.weather(.stormy)]),
        WellnessTip(id: "b3", text: "Nasal breathing filters and warms air, and activates your parasympathetic system.", category: .breathing, conditions: [.any]),
        WellnessTip(id: "b4", text: "A single deep breath takes 10 seconds and can shift your entire nervous system state.", category: .breathing, conditions: [.stormy]),
        WellnessTip(id: "b5", text: "Breathing at 5.5 breaths per minute maximizes heart rate variability.", category: .breathing, conditions: [.any]),
        WellnessTip(id: "b6", text: "Box breathing is used by Navy SEALs to stay calm under extreme pressure.", category: .breathing, conditions: [.weather(.stormy)]),
        WellnessTip(id: "b7", text: "Morning breathwork sets your autonomic tone for the entire day.", category: .breathing, conditions: [.morning]),
        WellnessTip(id: "b8", text: "End-of-day breathing helps transition from work mode to rest mode.", category: .breathing, conditions: [.evening]),
        WellnessTip(id: "b9", text: "Even 3 conscious breaths between tasks can prevent stress accumulation.", category: .breathing, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "b10", text: "Humming while exhaling stimulates the vagus nerve more than silent breathing.", category: .breathing, conditions: [.any]),
        WellnessTip(id: "b11", text: "Place one hand on chest, one on belly. Belly should move more — that's diaphragmatic breathing.", category: .breathing, conditions: [.any]),
        WellnessTip(id: "b12", text: "After a practice, your breathing pattern stays calmer for up to 2 hours.", category: .breathing, conditions: [.afterPractice]),

        // POSTURE (12)
        WellnessTip(id: "p1", text: "Sit bones grounded, spine tall, shoulders melted down. Your body shapes your stress response.", category: .posture, conditions: [.any]),
        WellnessTip(id: "p2", text: "Uncross your legs and plant both feet flat. Grounding starts with your foundation.", category: .posture, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "p3", text: "Roll your shoulders back 3 times. Desk work creates a forward-hunch stress posture.", category: .posture, conditions: [.any]),
        WellnessTip(id: "p4", text: "Jaw tension is the #1 unconscious stress signal. Unclench, let teeth part slightly.", category: .posture, conditions: [.weather(.stormy)]),
        WellnessTip(id: "p5", text: "Look away from the screen at something 20 feet away for 20 seconds. Your eyes need breaks too.", category: .posture, conditions: [.any]),
        WellnessTip(id: "p6", text: "Open your hands and place them palms-up on your thighs. Open posture = open mind.", category: .posture, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "p7", text: "Micro-stretch: interlace fingers, push palms to ceiling, hold 10 seconds.", category: .posture, conditions: [.any]),
        WellnessTip(id: "p8", text: "Your neck holds the weight of a bowling ball. Give it a gentle side-to-side stretch.", category: .posture, conditions: [.timeOfDay(12...15)]),
        WellnessTip(id: "p9", text: "Power posing for 2 minutes can reduce cortisol by up to 25%.", category: .posture, conditions: [.weather(.stormy)]),
        WellnessTip(id: "p10", text: "Slouching compresses your diaphragm, making deep breathing harder.", category: .posture, conditions: [.any]),
        WellnessTip(id: "p11", text: "Stand up and shake out your arms and legs for 10 seconds. Reset your body.", category: .posture, conditions: [.timeOfDay(14...17)]),
        WellnessTip(id: "p12", text: "Morning posture check: are your shoulders up by your ears? Let them drop.", category: .posture, conditions: [.morning]),

        // HYDRATION (12)
        WellnessTip(id: "h1", text: "Even mild dehydration impairs focus and increases anxiety. Take a sip of water.", category: .hydration, conditions: [.any]),
        WellnessTip(id: "h2", text: "Caffeine after 2pm disrupts sleep architecture. Switch to water or herbal tea.", category: .hydration, conditions: [.timeOfDay(14...20)]),
        WellnessTip(id: "h3", text: "Room temperature water is absorbed faster than cold water.", category: .hydration, conditions: [.any]),
        WellnessTip(id: "h4", text: "Stressed? Your body uses more water. Increase intake on high-stress days.", category: .hydration, conditions: [.weather(.stormy)]),
        WellnessTip(id: "h5", text: "Herbal teas like chamomile contain apigenin, which binds to GABA receptors for calm.", category: .hydration, conditions: [.evening]),
        WellnessTip(id: "h6", text: "Start your morning with a full glass of water before coffee. Rehydrate first.", category: .hydration, conditions: [.morning]),
        WellnessTip(id: "h7", text: "Green tea has L-theanine: calm focus without the caffeine jitters.", category: .hydration, conditions: [.timeOfDay(9...14)]),
        WellnessTip(id: "h8", text: "Dehydration reduces cognitive performance by up to 12%. Keep water visible on your desk.", category: .hydration, conditions: [.any]),
        WellnessTip(id: "h9", text: "The act of sipping water can be a mini-mindfulness moment. Notice the temperature and taste.", category: .hydration, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "h10", text: "Electrolytes matter too. A pinch of salt in water improves absorption.", category: .hydration, conditions: [.any]),
        WellnessTip(id: "h11", text: "Your brain is 75% water. Hydration directly affects your thinking clarity.", category: .hydration, conditions: [.any]),
        WellnessTip(id: "h12", text: "After a practice, have some water. It reinforces the relaxation response.", category: .hydration, conditions: [.afterPractice]),

        // BREAKS (12)
        WellnessTip(id: "br1", text: "The Pomodoro technique: 25 min focus, 5 min break. Your brain needs rhythm.", category: .breaks, conditions: [.any]),
        WellnessTip(id: "br2", text: "Look out a window. Natural light resets your circadian rhythm and lowers cortisol.", category: .breaks, conditions: [.any]),
        WellnessTip(id: "br3", text: "A 5-minute walk increases creative thinking by 60% (Stanford study).", category: .breaks, conditions: [.timeOfDay(10...16)]),
        WellnessTip(id: "br4", text: "Micro-breaks every 30 minutes prevent the stress snowball effect.", category: .breaks, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "br5", text: "Step outside for 2 minutes. Sunlight + movement is nature's stress antidote.", category: .breaks, conditions: [.weather(.stormy)]),
        WellnessTip(id: "br6", text: "Between meetings, take 60 seconds to stare at nothing. Let your brain defrag.", category: .breaks, conditions: [.any]),
        WellnessTip(id: "br7", text: "The best break is the one you take before you need it.", category: .breaks, conditions: [.consecutiveClear(3)]),
        WellnessTip(id: "br8", text: "Transition rituals matter: close old tabs before starting new work.", category: .breaks, conditions: [.any]),
        WellnessTip(id: "br9", text: "Afternoon slump? A 10-minute walk beats caffeine for sustained energy.", category: .breaks, conditions: [.timeOfDay(13...16)]),
        WellnessTip(id: "br10", text: "Context switching costs 23 minutes of refocus time. Batch similar tasks.", category: .breaks, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "br11", text: "End-of-day shutdown ritual: review tomorrow, close all apps, take 3 breaths.", category: .breaks, conditions: [.evening]),
        WellnessTip(id: "br12", text: "You just finished a practice. Ease back into work gently — don't rush.", category: .breaks, conditions: [.afterPractice]),

        // MINDSET (12)
        WellnessTip(id: "m1", text: "Name your emotion. 'I'm feeling anxious' reduces amygdala activity by 43%.", category: .mindset, conditions: [.weather(.stormy)]),
        WellnessTip(id: "m2", text: "Reframe: stress means you care. Channel it, don't fight it.", category: .mindset, conditions: [.weather(.stormy)]),
        WellnessTip(id: "m3", text: "You don't have to believe every thought you think.", category: .mindset, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "m4", text: "'What's the one most important thing right now?' Focus narrows stress.", category: .mindset, conditions: [.weather(.stormy)]),
        WellnessTip(id: "m5", text: "Gratitude practice: name 3 things going well right now, however small.", category: .mindset, conditions: [.any]),
        WellnessTip(id: "m6", text: "Perfectionism is procrastination in disguise. Done > perfect.", category: .mindset, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "m7", text: "Your thoughts are weather — they pass. You are the sky.", category: .mindset, conditions: [.any]),
        WellnessTip(id: "m8", text: "Self-compassion: would you say this to a friend? Treat yourself the same way.", category: .mindset, conditions: [.weather(.stormy)]),
        WellnessTip(id: "m9", text: "Progress, not perfection. What did you accomplish today?", category: .mindset, conditions: [.evening]),
        WellnessTip(id: "m10", text: "Set an intention for this work block. Purpose reduces perceived stress.", category: .mindset, conditions: [.morning]),
        WellnessTip(id: "m11", text: "Great work staying calm today. Consistency builds resilience.", category: .mindset, conditions: [.consecutiveClear(3)]),
        WellnessTip(id: "m12", text: "That practice was an investment in yourself. Well done.", category: .mindset, conditions: [.afterPractice]),

        // SOCIAL (12)
        WellnessTip(id: "s1", text: "Send a quick message to someone you appreciate. Social connection lowers cortisol.", category: .social, conditions: [.any]),
        WellnessTip(id: "s2", text: "Feeling overwhelmed? Delegate one thing. Asking for help is a strength.", category: .social, conditions: [.weather(.stormy)]),
        WellnessTip(id: "s3", text: "A 2-minute non-work conversation can reset your stress levels.", category: .social, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "s4", text: "Eye contact and smiling trigger oxytocin — even over video calls.", category: .social, conditions: [.any]),
        WellnessTip(id: "s5", text: "Loneliness is as harmful as smoking 15 cigarettes a day. Stay connected.", category: .social, conditions: [.any]),
        WellnessTip(id: "s6", text: "Share how you're feeling with a trusted colleague. Vulnerability builds trust.", category: .social, conditions: [.weather(.stormy)]),
        WellnessTip(id: "s7", text: "Compliment someone's work today. Generosity reduces your own stress.", category: .social, conditions: [.morning]),
        WellnessTip(id: "s8", text: "Lunch with a friend > lunch at your desk. Protect your social time.", category: .social, conditions: [.timeOfDay(11...13)]),
        WellnessTip(id: "s9", text: "Boundaries are a form of self-care. It's OK to say no to that meeting.", category: .social, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "s10", text: "After a good day, share what went well with someone. Positive reflection multiplies.", category: .social, conditions: [.consecutiveClear(3)]),
        WellnessTip(id: "s11", text: "Call instead of emailing. Voice connection releases more oxytocin than text.", category: .social, conditions: [.any]),
        WellnessTip(id: "s12", text: "Who made your day better? Tell them.", category: .social, conditions: [.evening]),

        // MOVEMENT (12)
        WellnessTip(id: "mv1", text: "Stand up and stretch. Sitting for 30+ minutes reduces blood flow to the brain.", category: .movement, conditions: [.any]),
        WellnessTip(id: "mv2", text: "Shake your hands vigorously for 10 seconds. It releases physical tension fast.", category: .movement, conditions: [.weather(.stormy)]),
        WellnessTip(id: "mv3", text: "Walk while on your next phone call. Movement + fresh air = stress relief.", category: .movement, conditions: [.any]),
        WellnessTip(id: "mv4", text: "Dancing for 30 seconds releases endorphins. Nobody's watching — try it.", category: .movement, conditions: [.any]),
        WellnessTip(id: "mv5", text: "Tense every muscle for 5 seconds, then release. Feel the difference.", category: .movement, conditions: [.weather(.stormy)]),
        WellnessTip(id: "mv6", text: "10 squats at your desk takes 30 seconds and boosts circulation immediately.", category: .movement, conditions: [.timeOfDay(14...17)]),
        WellnessTip(id: "mv7", text: "A morning stretch routine sets the tone for a calmer day.", category: .movement, conditions: [.morning]),
        WellnessTip(id: "mv8", text: "Wrist circles and finger stretches — your hands work harder than you think.", category: .movement, conditions: [.any]),
        WellnessTip(id: "mv9", text: "Walk to the farthest bathroom or water fountain. Extra steps = extra calm.", category: .movement, conditions: [.weather(.cloudy)]),
        WellnessTip(id: "mv10", text: "Post-practice movement helps integrate the calm into your body.", category: .movement, conditions: [.afterPractice]),
        WellnessTip(id: "mv11", text: "Gentle neck rolls: 3 clockwise, 3 counter-clockwise. Release screen strain.", category: .movement, conditions: [.any]),
        WellnessTip(id: "mv12", text: "An evening walk, even 10 minutes, dramatically improves sleep quality.", category: .movement, conditions: [.evening]),

        // NUTRITION (12)
        WellnessTip(id: "n1", text: "Complex carbs (oats, whole grain) boost serotonin. Simple sugars spike then crash.", category: .nutrition, conditions: [.morning]),
        WellnessTip(id: "n2", text: "Magnesium-rich foods (dark chocolate, nuts, spinach) support calm nervous system function.", category: .nutrition, conditions: [.any]),
        WellnessTip(id: "n3", text: "Blood sugar crashes mimic anxiety. Eat regular small meals, not one big one.", category: .nutrition, conditions: [.timeOfDay(11...14)]),
        WellnessTip(id: "n4", text: "Omega-3 fatty acids (fish, walnuts, flax) reduce inflammation and anxiety markers.", category: .nutrition, conditions: [.any]),
        WellnessTip(id: "n5", text: "Stress depletes B vitamins. Leafy greens, eggs, and whole grains replenish them.", category: .nutrition, conditions: [.weather(.stormy)]),
        WellnessTip(id: "n6", text: "Dark chocolate (70%+) contains theobromine and flavanols that reduce cortisol.", category: .nutrition, conditions: [.timeOfDay(14...17)]),
        WellnessTip(id: "n7", text: "Gut health = mental health. Fermented foods support your microbiome-brain axis.", category: .nutrition, conditions: [.any]),
        WellnessTip(id: "n8", text: "Avoid eating at your desk. Mindful eating is a form of stress management.", category: .nutrition, conditions: [.timeOfDay(12...13)]),
        WellnessTip(id: "n9", text: "Protein at breakfast stabilizes blood sugar and mood for hours.", category: .nutrition, conditions: [.morning]),
        WellnessTip(id: "n10", text: "Bananas contain tryptophan + vitamin B6 — the building blocks of serotonin.", category: .nutrition, conditions: [.any]),
        WellnessTip(id: "n11", text: "Alcohol disrupts sleep architecture even in small amounts. Choose wisely tonight.", category: .nutrition, conditions: [.evening]),
        WellnessTip(id: "n12", text: "Your body craves nutrients when stressed, not comfort food. Listen to what it really needs.", category: .nutrition, conditions: [.weather(.stormy)]),
    ]
}
