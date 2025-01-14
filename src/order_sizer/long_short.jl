"""
Create target portfolio quantities using the total equity
available to the order sizer.

Fields
------
- `broker::Broker`
- `portfolio_id::String`
- `gross_leverage::Float64=1.0`
"""
struct LongShortOrderSizer <: OrderSizer
    gross_leverage::Float64
    function LongShortOrderSizer(gross_leverage::Float64=1.0)
        @assert (gross_leverage > 0.0) "gross_leverage must be positive"
        return new(gross_leverage)
    end
end

function (order_sizer::LongShortOrderSizer)(
    broker::Broker, portfolio_id::String, weights::Dict, dt::DateTime
)
    portfolio_equity = total_equity(broker.portfolios[portfolio_id])

    # no weights
    if length(weights) == 0
        return Dict{Asset,Int}()
    end

    normalized_weights = _normalize_weights(weights)
    target_portfolio = Dict{Asset,Int}()
    for (asset, weight) in normalized_weights
        dollar_weight = portfolio_equity * order_sizer.gross_leverage * weight
        price = get_asset_latest_ask_price(broker.data_handler, dt, asset.symbol)
        if isnan(price)
            @warn "Unable to get price of asset $asset at $dt. Setting quantity to 0."
            asset_quantity = 0
        else
            asset_quantity = _calculate_asset_quantity(
                broker.fee_model, dollar_weight, price
            )
        end
        target_portfolio[asset] = asset_quantity
    end
    return target_portfolio
end
