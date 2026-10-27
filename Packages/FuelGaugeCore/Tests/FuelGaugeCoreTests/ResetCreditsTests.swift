import Foundation
@testable import FuelGaugeCore
import Testing

struct ResetCreditsTests {
    @Test func missingIsNotZero() throws {
        #expect(try ResetCredits.decode(Data("{}".utf8)) == nil)
        #expect(try ResetCredits.decode(Data(#"{"rateLimitResetCredits":null}"#.utf8)) == nil)
        let zero = try ResetCredits.decode(Data(#"{"rateLimitResetCredits":{"availableCount":0}}"#.utf8))
        #expect(zero?.summary() == "No resets available")
    }

    @Test func countIsAuthoritativeWhenDetailsArePartial() throws {
        let json = #"{"rateLimitResetCredits":{"availableCount":2,"credits":"#
            + #"[{"status":"available","expiresAt":2000000000}]}}"#
        let data = Data(json.utf8)
        let credits = try #require(try ResetCredits.decode(data))
        #expect(credits.summary(now: Date(timeIntervalSince1970: 1)) == "2 resets available")
        #expect(credits.nextExpiration == Date(timeIntervalSince1970: 2_000_000_000))
        let expired = credits.summary(now: Date(timeIntervalSince1970: 2_000_000_001))
        #expect(expired == "Reset availability needs refreshing")
    }

    @Test func countOnlyAndInvalidCount() throws {
        let data = Data(#"{"rateLimitResetCredits":{"availableCount":1,"credits":null}}"#.utf8)
        let credits = try #require(try ResetCredits.decode(data))
        #expect(credits.summary() == "1 reset available")
        #expect(credits.nextExpiration == nil)
        #expect(try ResetCredits.decode(Data(#"{"rateLimitResetCredits":{"availableCount":-1}}"#.utf8)) == nil)
    }
}
