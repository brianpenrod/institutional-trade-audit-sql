/* PROJECT: Institutional Trade Execution Audit
   AUTHOR: Brian Penrod, DBA
   PLATFORM: Google BigQuery (Standard SQL)
   
   BUSINESS OBJECTIVE: 
   To audit proprietary trading performance against institutional benchmarks (VWAP) 
   and identifying risk regimes using algorithmic logic.
   
   KEY TECHNICAL FEATURES:
   1. Window Functions: Used to calculate rolling volatility and mean reversion.
   2. CTEs (Common Table Expressions): Used to structure raw data ingestion.
   3. Feature Engineering: Algorithmic construction of Stochastic Oscillators.
*/

-- STEP 1: INGEST AND NORMALIZE RAW LOGS
WITH market_data AS (
    SELECT 
        ContractName AS ticker,
        EnteredAt AS execution_time,
        EntryPrice AS price, 
        Size AS quantity,
        PnL AS pnl,
        
        -- Calculate 14-Period Rolling High (Algorithmic Lookback)
        MAX(EntryPrice) OVER (
            PARTITION BY ContractName 
            ORDER BY EnteredAt 
            ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
        ) AS rolling_high_14,
        
        -- Calculate 14-Period Rolling Low
        MIN(EntryPrice) OVER (
            PARTITION BY ContractName 
            ORDER BY EnteredAt 
            ROWS BETWEEN 13 PRECEDING AND CURRENT ROW
        ) AS rolling_low_14
        
    FROM `bp_capital.trade_log` -- (Sanitized Table Name)
),

-- STEP 2: CALCULATE INSTITUTIONAL INDICATORS
quant_calculations AS (
    SELECT
        *,
        -- VWAP (Volume Weighted Average Price) Calculation
        -- Formula: Cumulative(Price * Vol) / Cumulative(Vol)
        SUM(price * quantity) OVER (PARTITION BY ticker ORDER BY execution_time) / 
        SUM(quantity) OVER (PARTITION BY ticker ORDER BY execution_time) AS vwap_value,

        -- Rolling Win Rate (10-Trade Window) for Risk Auditing
        AVG(CASE WHEN pnl > 0 THEN 1.0 ELSE 0.0 END) OVER (
            PARTITION BY ticker 
            ORDER BY execution_time 
            ROWS BETWEEN 9 PRECEDING AND CURRENT ROW
        ) AS rolling_win_rate_10
    FROM market_data
)

-- STEP 3: FINAL RISK & EXECUTION REPORT
SELECT
    ticker,
    execution_time,
    price,
    pnl,
    rolling_win_rate_10,
    ROUND(vwap_value, 2) AS vwap,
    
    -- Stochastic Oscillator Construction
    -- Signal: >80 (Overbought) | <20 (Oversold)
    CASE 
        WHEN rolling_high_14 = rolling_low_14 THEN 50 
        ELSE ROUND(100 * (price - rolling_low_14) / (rolling_high_14 - rolling_low_14), 1)
    END AS stochastic_indicator,

    -- Automated Risk Flagging System
    CASE 
        WHEN rolling_win_rate_10 < 0.3 THEN 'CRITICAL: STOP TRADING'
        WHEN rolling_win_rate_10 > 0.8 THEN 'HIGH PERFORMANCE'
        ELSE 'NORMAL' 
    END AS risk_status

FROM quant_calculations
ORDER BY ticker, execution_time DESC;
