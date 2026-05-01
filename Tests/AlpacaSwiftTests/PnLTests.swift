import XCTest
@testable import AlpacaSwift

final class PnLTests: XCTestCase {

    // MARK: - Order factory

    private static let symbol = "AAPL"
    private static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    private static func makeOrder(
        id: UUID = UUID(),
        symbol: String = symbol,
        side: Order.Side,
        qty: Double,
        filledQty: Double? = nil,
        filledAvgPrice: Double?,
        status: Order.Status = .filled,
        filledAtOffset: TimeInterval,
        legs: [Order]? = nil,
        orderClass: Order.Class? = nil
    ) -> Order {
        let actualFilledQty = filledQty ?? qty
        return Order(
            id: id,
            clientOrderId: "",
            createdAt: baseDate,
            updatedAt: nil,
            submittedAt: baseDate.addingTimeInterval(filledAtOffset),
            filledAt: baseDate.addingTimeInterval(filledAtOffset),
            expiredAt: nil,
            canceledAt: nil,
            failedAt: nil,
            replacedAt: nil,
            replacedBy: nil,
            replaces: nil,
            assetId: UUID(),
            symbol: symbol,
            assetClass: .usEquity,
            qty: NumericString(value: qty),
            filledQty: NumericString(value: actualFilledQty),
            type: .market,
            side: side,
            timeInForce: .day,
            limitPrice: nil,
            stopPrice: nil,
            filledAvgPrice: filledAvgPrice.map { NumericString(value: $0) },
            status: status,
            extendedHours: false,
            legs: legs,
            order_class: orderClass,
            trailPrice: nil,
            trailPercent: nil,
            notional: nil,
            positionIntent: nil
        )
    }

    // MARK: - PnL: long round-trips

    func testPnL_longRoundTrip() throws {
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let sell = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 110, filledAtOffset: 60)
        let history = [buy, sell]

        XCTAssertNil(buy.pnl(orderHistory: history), "Opening order should have no realized PnL")
        XCTAssertEqual(sell.pnl(orderHistory: history) ?? .nan, 100, accuracy: 1e-9)
    }

    func testPnL_longPartialClose() throws {
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let sell1 = Self.makeOrder(side: .sell, qty: 5, filledAvgPrice: 110, filledAtOffset: 60)
        let sell2 = Self.makeOrder(side: .sell, qty: 5, filledAvgPrice: 115, filledAtOffset: 120)
        let history = [buy, sell1, sell2]

        XCTAssertEqual(sell1.pnl(orderHistory: history) ?? .nan, 50, accuracy: 1e-9)
        XCTAssertEqual(sell2.pnl(orderHistory: history) ?? .nan, 75, accuracy: 1e-9)
    }

    func testPnL_longFIFOAcrossLots() throws {
        // Buy 10 @ 100, buy 10 @ 120, sell 15 @ 130
        // FIFO PnL = 10*(130-100) + 5*(130-120) = 350
        let buy1 = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let buy2 = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 120, filledAtOffset: 60)
        let sell = Self.makeOrder(side: .sell, qty: 15, filledAvgPrice: 130, filledAtOffset: 120)
        let history = [buy1, buy2, sell]

        XCTAssertEqual(sell.pnl(orderHistory: history) ?? .nan, 350, accuracy: 1e-9)
    }

    // MARK: - PnL: shorts

    func testPnL_shortRoundTrip() throws {
        // Sell short 10 @ 100, cover 10 @ 90 → PnL = +100
        let sell = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let cover = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 90, filledAtOffset: 60)
        let history = [sell, cover]

        XCTAssertNil(sell.pnl(orderHistory: history), "Opening short should have no realized PnL")
        XCTAssertEqual(cover.pnl(orderHistory: history) ?? .nan, 100, accuracy: 1e-9)
    }

    func testPnL_shortLossing() throws {
        let sell = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let cover = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 115, filledAtOffset: 60)
        let history = [sell, cover]

        XCTAssertEqual(cover.pnl(orderHistory: history) ?? .nan, -150, accuracy: 1e-9)
    }

    // MARK: - PnL: reversal

    func testPnL_reversalFromLongToShort() throws {
        // Buy 10 @ 100, sell 15 @ 110: closes 10 long for +100, opens 5 short @ 110
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let sell = Self.makeOrder(side: .sell, qty: 15, filledAvgPrice: 110, filledAtOffset: 60)
        let history = [buy, sell]

        XCTAssertEqual(sell.pnl(orderHistory: history) ?? .nan, 100, accuracy: 1e-9)

        // Cover the residual short at 105 → +5*(110-105) = +25
        let cover = Self.makeOrder(side: .buy, qty: 5, filledAvgPrice: 105, filledAtOffset: 120)
        let history2 = [buy, sell, cover]

        XCTAssertEqual(cover.pnl(orderHistory: history2) ?? .nan, 25, accuracy: 1e-9)
    }

    // MARK: - PnL: bracket short-circuit

    func testPnL_bracketParentShortCircuit_buy() throws {
        // Bracket buy parent fills @ 100, take-profit leg sells 10 @ 110 → +100
        let leg = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 110, filledAtOffset: 60)
        let parent = Self.makeOrder(
            side: .buy,
            qty: 10,
            filledAvgPrice: 100,
            filledAtOffset: 0,
            legs: [leg],
            orderClass: .bracket
        )

        // History contains only the parent (legs aren't returned at top level under nested:true)
        XCTAssertEqual(parent.pnl(orderHistory: [parent]) ?? .nan, 100, accuracy: 1e-9)
    }

    func testPnL_bracketParentShortCircuit_sell() throws {
        // Short bracket: parent sells short @ 100, leg buys 10 @ 90 → +100
        let leg = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 90, filledAtOffset: 60)
        let parent = Self.makeOrder(
            side: .sell,
            qty: 10,
            filledAvgPrice: 100,
            filledAtOffset: 0,
            legs: [leg],
            orderClass: .bracket
        )

        XCTAssertEqual(parent.pnl(orderHistory: [parent]) ?? .nan, 100, accuracy: 1e-9)
    }

    // MARK: - PnL: bracket round-trip in history shouldn't pollute later orders

    func testPnL_bracketRoundTripDoesNotPolluteLaterOrders() throws {
        // Bracket buy @ 100 / leg sell @ 110 closes the position cleanly.
        // Then a separate buy @ 200 / sell @ 210 round-trip should stand on its own.
        let bracketLeg = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 110, filledAtOffset: 60)
        let bracketParent = Self.makeOrder(
            side: .buy,
            qty: 10,
            filledAvgPrice: 100,
            filledAtOffset: 0,
            legs: [bracketLeg],
            orderClass: .bracket
        )

        let laterBuy = Self.makeOrder(side: .buy, qty: 5, filledAvgPrice: 200, filledAtOffset: 600)
        let laterSell = Self.makeOrder(side: .sell, qty: 5, filledAvgPrice: 210, filledAtOffset: 660)

        let history = [bracketParent, laterBuy, laterSell]

        // Pre-fix bug: bracket parent left a phantom long lot, so laterSell would
        // have FIFO-matched against the 100 buy and reported +(210-100)*5 = 550.
        // Correct PnL is the standalone round-trip: +(210-200)*5 = 50.
        XCTAssertEqual(laterSell.pnl(orderHistory: history) ?? .nan, 50, accuracy: 1e-9)
    }

    // MARK: - PnL: ignores other symbols

    func testPnL_otherSymbolsDoNotAffectCalculation() throws {
        let aaplBuy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let aaplSell = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 110, filledAtOffset: 60)
        let tslaBuy = Self.makeOrder(symbol: "TSLA", side: .buy, qty: 1, filledAvgPrice: 250, filledAtOffset: 30)
        let tslaSell = Self.makeOrder(symbol: "TSLA", side: .sell, qty: 1, filledAvgPrice: 200, filledAtOffset: 90)

        let history = [aaplBuy, aaplSell, tslaBuy, tslaSell]

        XCTAssertEqual(aaplSell.pnl(orderHistory: history) ?? .nan, 100, accuracy: 1e-9)
        XCTAssertEqual(tslaSell.pnl(orderHistory: history) ?? .nan, -50, accuracy: 1e-9)
    }

    // MARK: - PnL: ordering insensitivity (history may arrive out of order)

    func testPnL_handlesUnsortedHistory() throws {
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let sell = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 110, filledAtOffset: 60)

        // Sell appears first in array; function should sort by filledAt.
        let history = [sell, buy]
        XCTAssertEqual(sell.pnl(orderHistory: history) ?? .nan, 100, accuracy: 1e-9)
    }

    // MARK: - positionContext

    func testPositionContext_openingLong() throws {
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let ctx = buy.positionContext(orderHistory: [buy])
        XCTAssertEqual(ctx?.action, "Opening Long")
        XCTAssertEqual(ctx?.positionBefore, 0)
        XCTAssertEqual(ctx?.positionAfter, 10)
    }

    func testPositionContext_extendingLong() throws {
        let buy1 = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let buy2 = Self.makeOrder(side: .buy, qty: 5, filledAvgPrice: 105, filledAtOffset: 60)
        let ctx = buy2.positionContext(orderHistory: [buy1, buy2])
        XCTAssertEqual(ctx?.action, "Extending Long")
        XCTAssertEqual(ctx?.positionBefore, 10)
        XCTAssertEqual(ctx?.positionAfter, 15)
    }

    func testPositionContext_closingLong() throws {
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let sell = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 110, filledAtOffset: 60)
        let ctx = sell.positionContext(orderHistory: [buy, sell])
        XCTAssertEqual(ctx?.action, "Closing Long")
        XCTAssertEqual(ctx?.positionBefore, 10)
        XCTAssertEqual(ctx?.positionAfter, 0)
    }

    func testPositionContext_reducingLong() throws {
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let sell = Self.makeOrder(side: .sell, qty: 4, filledAvgPrice: 110, filledAtOffset: 60)
        let ctx = sell.positionContext(orderHistory: [buy, sell])
        XCTAssertEqual(ctx?.action, "Reducing Long")
        XCTAssertEqual(ctx?.positionBefore, 10)
        XCTAssertEqual(ctx?.positionAfter, 6)
    }

    func testPositionContext_reversingToShort() throws {
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let sell = Self.makeOrder(side: .sell, qty: 15, filledAvgPrice: 110, filledAtOffset: 60)
        let ctx = sell.positionContext(orderHistory: [buy, sell])
        XCTAssertEqual(ctx?.action, "Reversing to Short")
        XCTAssertEqual(ctx?.positionBefore, 10)
        XCTAssertEqual(ctx?.positionAfter, -5)
    }

    func testPositionContext_afterBracketRoundTripIsFlat() throws {
        // Bracket round-trip in history should leave position flat for next order's context.
        let bracketLeg = Self.makeOrder(side: .sell, qty: 10, filledAvgPrice: 110, filledAtOffset: 60)
        let bracketParent = Self.makeOrder(
            side: .buy,
            qty: 10,
            filledAvgPrice: 100,
            filledAtOffset: 0,
            legs: [bracketLeg],
            orderClass: .bracket
        )

        let nextBuy = Self.makeOrder(side: .buy, qty: 3, filledAvgPrice: 200, filledAtOffset: 600)
        let history = [bracketParent, nextBuy]

        let ctx = nextBuy.positionContext(orderHistory: history)
        XCTAssertEqual(ctx?.action, "Opening Long")
        XCTAssertEqual(ctx?.positionBefore, 0)
        XCTAssertEqual(ctx?.positionAfter, 3)
    }

    // MARK: - Defensive dedupe

    func testPnL_dedupesDuplicateOrderEntries() throws {
        // Real-world bug: caller's history accumulated multiple copies of the
        // same Order id (cache write-back not deduped). Position math should
        // not multiply with each duplicate.
        let buy = Self.makeOrder(side: .buy, qty: 10, filledAvgPrice: 100, filledAtOffset: 0)
        let sell = Self.makeOrder(side: .sell, qty: 4, filledAvgPrice: 110, filledAtOffset: 60)
        let history = [buy, buy, buy, sell, sell, sell]

        XCTAssertEqual(sell.pnl(orderHistory: history) ?? .nan, 40, accuracy: 1e-9)
    }

    func testPositionContext_dedupesDuplicateOrderEntries() throws {
        let buy = Self.makeOrder(side: .buy, qty: 14, filledAvgPrice: 100, filledAtOffset: 0)
        let sell = Self.makeOrder(side: .sell, qty: 7, filledAvgPrice: 110, filledAtOffset: 60)

        // Same orders entered hundreds of times — this is exactly the MRVL
        // pattern that produced "+14 → +7" with a 271x duplicate.
        let history = Array(repeating: buy, count: 5) + Array(repeating: sell, count: 271)
        let ctx = sell.positionContext(orderHistory: history)
        XCTAssertEqual(ctx?.action, "Reducing Long")
        XCTAssertEqual(ctx?.positionBefore, 14)
        XCTAssertEqual(ctx?.positionAfter, 7)
    }

    func testPositionContext_unfilledOrderReturnsNil() throws {
        let unfilled = Self.makeOrder(
            side: .buy,
            qty: 10,
            filledQty: 0,
            filledAvgPrice: nil,
            status: .new,
            filledAtOffset: 0
        )
        XCTAssertNil(unfilled.positionContext(orderHistory: [unfilled]))
    }
}
