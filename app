import { useState, useEffect } from "react";
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from "recharts";

const COLORS = ["#4f8ef7", "#34d399", "#f59e0b", "#f87171", "#a78bfa", "#60a5fa", "#fb923c"];

const initialHoldings = [
  { id: 1, symbol: "AAPL", name: "蘋果", shares: 10, buyPrice: 170, currentPrice: 213 },
  { id: 2, symbol: "TSLA", name: "特斯拉", shares: 5, buyPrice: 250, currentPrice: 298 },
  { id: 3, symbol: "NVDA", name: "輝達", shares: 3, buyPrice: 500, currentPrice: 1070 },
];

function formatTWD(num) {
  return num.toLocaleString("zh-TW", { minimumFractionDigits: 0, maximumFractionDigits: 0 });
}

function formatPct(num) {
  return (num >= 0 ? "+" : "") + num.toFixed(2) + "%";
}

export default function App() {
  const [holdings, setHoldings] = useState(initialHoldings);
  const [form, setForm] = useState({ symbol: "", name: "", shares: "", buyPrice: "", currentPrice: "" });
  const [aiAnalysis, setAiAnalysis] = useState("");
  const [aiLoading, setAiLoading] = useState(false);
  const [showAdd, setShowAdd] = useState(false);
  const [nextId, setNextId] = useState(10);
  const [activeTab, setActiveTab] = useState("holdings");

  const totalCost = holdings.reduce((s, h) => s + h.shares * h.buyPrice, 0);
  const totalValue = holdings.reduce((s, h) => s + h.shares * h.currentPrice, 0);
  const totalPnL = totalValue - totalCost;
  const totalPnLPct = totalCost > 0 ? (totalPnL / totalCost) * 100 : 0;

  const pieData = holdings.map((h) => ({
    name: h.symbol,
    value: h.shares * h.currentPrice,
  }));

  function addHolding() {
    if (!form.symbol || !form.shares || !form.buyPrice || !form.currentPrice) return;
    setHoldings([
      ...holdings,
      {
        id: nextId,
        symbol: form.symbol.toUpperCase(),
        name: form.name || form.symbol.toUpperCase(),
        shares: parseFloat(form.shares),
        buyPrice: parseFloat(form.buyPrice),
        currentPrice: parseFloat(form.currentPrice),
      },
    ]);
    setNextId(nextId + 1);
    setForm({ symbol: "", name: "", shares: "", buyPrice: "", currentPrice: "" });
    setShowAdd(false);
  }

  function removeHolding(id) {
    setHoldings(holdings.filter((h) => h.id !== id));
  }

  async function getAiAnalysis() {
    setAiLoading(true);
    setAiAnalysis("");
    setActiveTab("ai");

    const portfolioDesc = holdings
      .map((h) => {
        const pnl = ((h.currentPrice - h.buyPrice) / h.buyPrice) * 100;
        return `${h.name}(${h.symbol})：持有${h.shares}股，買入價$${h.buyPrice}，現價$${h.currentPrice}，報酬率${pnl.toFixed(1)}%`;
      })
      .join("\n");

    const prompt = `你是一位專業的投資顧問。以下是用戶的投資組合：

${portfolioDesc}

總投入：$${formatTWD(totalCost)}
目前市值：$${formatTWD(totalValue)}
總損益：${totalPnL >= 0 ? "+" : ""}$${formatTWD(totalPnL)}（${formatPct(totalPnLPct)}）

請用繁體中文，以友善且專業的語氣，分析這個投資組合的：
1. 整體表現評估
2. 持倉集中度與風險
3. 表現最好與最差的持股
4. 簡單的改善建議（2-3點）

請保持回答簡潔，使用條列式說明，每點不超過兩句話。`;

    try {
      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: "claude-sonnet-4-6",
          max_tokens: 1000,
          messages: [{ role: "user", content: prompt }],
        }),
      });
      const data = await response.json();
      const text = data.content?.map((c) => c.text || "").join("") || "無法取得分析，請稍後再試。";
      setAiAnalysis(text);
    } catch (e) {
      setAiAnalysis("連線失敗，請稍後再試。");
    }
    setAiLoading(false);
  }

  return (
    <div style={{ minHeight: "100vh", background: "#0d1117", color: "#e6edf3", fontFamily: "'Inter', system-ui, sans-serif" }}>
      {/* Header */}
      <div style={{ background: "linear-gradient(135deg, #161b22 0%, #0d1117 100%)", borderBottom: "1px solid #21262d", padding: "20px 24px" }}>
        <div style={{ maxWidth: 900, margin: "0 auto" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div>
              <h1 style={{ margin: 0, fontSize: 22, fontWeight: 700, color: "#4f8ef7", letterSpacing: "-0.5px" }}>
                📊 投資組合追蹤器
              </h1>
              <p style={{ margin: "4px 0 0", fontSize: 13, color: "#8b949e" }}>使用 AI 分析你的持倉表現</p>
            </div>
            <button
              onClick={getAiAnalysis}
              disabled={holdings.length === 0 || aiLoading}
              style={{
                background: aiLoading ? "#21262d" : "linear-gradient(135deg, #4f8ef7, #6b7aff)",
                color: "#fff",
                border: "none",
                borderRadius: 10,
                padding: "10px 18px",
                fontSize: 13,
                fontWeight: 600,
                cursor: aiLoading || holdings.length === 0 ? "not-allowed" : "pointer",
                opacity: holdings.length === 0 ? 0.5 : 1,
              }}
            >
              {aiLoading ? "⏳ 分析中..." : "🤖 AI 分析"}
            </button>
          </div>
        </div>
      </div>

      <div style={{ maxWidth: 900, margin: "0 auto", padding: "24px 16px" }}>
        {/* Summary Cards */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12, marginBottom: 24 }}>
          {[
            { label: "總投入", value: `$${formatTWD(totalCost)}`, color: "#8b949e" },
            { label: "目前市值", value: `$${formatTWD(totalValue)}`, color: "#4f8ef7" },
            {
              label: "總損益",
              value: `${totalPnL >= 0 ? "+" : ""}$${formatTWD(totalPnL)}`,
              sub: formatPct(totalPnLPct),
              color: totalPnL >= 0 ? "#34d399" : "#f87171",
            },
          ].map((card) => (
            <div key={card.label} style={{ background: "#161b22", border: "1px solid #21262d", borderRadius: 12, padding: "16px 20px" }}>
              <div style={{ fontSize: 12, color: "#8b949e", marginBottom: 6 }}>{card.label}</div>
              <div style={{ fontSize: 20, fontWeight: 700, color: card.color }}>{card.value}</div>
              {card.sub && <div style={{ fontSize: 12, color: card.color, marginTop: 2 }}>{card.sub}</div>}
            </div>
          ))}
        </div>

        {/* Tabs */}
        <div style={{ display: "flex", gap: 4, marginBottom: 20, borderBottom: "1px solid #21262d", paddingBottom: 0 }}>
          {["holdings", "chart", "ai"].map((tab) => {
            const labels = { holdings: "📋 持倉明細", chart: "🥧 配置圖", ai: "🤖 AI 分析" };
            return (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                style={{
                  background: "none",
                  border: "none",
                  borderBottom: activeTab === tab ? "2px solid #4f8ef7" : "2px solid transparent",
                  color: activeTab === tab ? "#4f8ef7" : "#8b949e",
                  padding: "10px 16px",
                  fontSize: 13,
                  fontWeight: activeTab === tab ? 600 : 400,
                  cursor: "pointer",
                  marginBottom: -1,
                }}
              >
                {labels[tab]}
              </button>
            );
          })}
        </div>

        {/* Holdings Tab */}
        {activeTab === "holdings" && (
          <div>
            <div style={{ display: "flex", justifyContent: "flex-end", marginBottom: 16 }}>
              <button
                onClick={() => setShowAdd(!showAdd)}
                style={{
                  background: showAdd ? "#21262d" : "#238636",
                  color: "#fff",
                  border: "none",
                  borderRadius: 8,
                  padding: "8px 16px",
                  fontSize: 13,
                  fontWeight: 600,
                  cursor: "pointer",
                }}
              >
                {showAdd ? "✕ 取消" : "+ 新增持倉"}
              </button>
            </div>

            {/* Add Form */}
            {showAdd && (
              <div style={{ background: "#161b22", border: "1px solid #30363d", borderRadius: 12, padding: 20, marginBottom: 16 }}>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12, marginBottom: 12 }}>
                  {[
                    { key: "symbol", label: "股票代號", placeholder: "如：AAPL" },
                    { key: "name", label: "股票名稱", placeholder: "如：蘋果（可選）" },
                    { key: "shares", label: "持有股數", placeholder: "如：10" },
                    { key: "buyPrice", label: "買入價格（$）", placeholder: "如：170" },
                    { key: "currentPrice", label: "現在價格（$）", placeholder: "如：213" },
                  ].map((f) => (
                    <div key={f.key}>
                      <label style={{ display: "block", fontSize: 12, color: "#8b949e", marginBottom: 6 }}>{f.label}</label>
                      <input
                        value={form[f.key]}
                        onChange={(e) => setForm({ ...form, [f.key]: e.target.value })}
                        placeholder={f.placeholder}
                        style={{
                          width: "100%",
                          background: "#0d1117",
                          border: "1px solid #30363d",
                          borderRadius: 8,
                          padding: "8px 12px",
                          color: "#e6edf3",
                          fontSize: 13,
                          boxSizing: "border-box",
                        }}
                      />
                    </div>
                  ))}
                </div>
                <button
                  onClick={addHolding}
                  style={{
                    background: "#238636",
                    color: "#fff",
                    border: "none",
                    borderRadius: 8,
                    padding: "10px 24px",
                    fontSize: 13,
                    fontWeight: 600,
                    cursor: "pointer",
                  }}
                >
                  確認新增
                </button>
              </div>
            )}

            {/* Holdings Table */}
            {holdings.length === 0 ? (
              <div style={{ textAlign: "center", padding: 60, color: "#8b949e" }}>
                <div style={{ fontSize: 40, marginBottom: 12 }}>📭</div>
                <div style={{ fontSize: 16, fontWeight: 600 }}>還沒有持倉</div>
                <div style={{ fontSize: 13, marginTop: 6 }}>點擊「新增持倉」開始追蹤你的投資</div>
              </div>
            ) : (
              <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
                {holdings.map((h, i) => {
                  const value = h.shares * h.currentPrice;
                  const cost = h.shares * h.buyPrice;
                  const pnl = value - cost;
                  const pnlPct = (pnl / cost) * 100;
                  const weight = ((value / totalValue) * 100).toFixed(1);
                  return (
                    <div
                      key={h.id}
                      style={{
                        background: "#161b22",
                        border: "1px solid #21262d",
                        borderRadius: 12,
                        padding: "16px 20px",
                        display: "flex",
                        alignItems: "center",
                        gap: 16,
                      }}
                    >
                      <div
                        style={{
                          width: 40,
                          height: 40,
                          borderRadius: 10,
                          background: COLORS[i % COLORS.length] + "22",
                          border: `2px solid ${COLORS[i % COLORS.length]}`,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          fontSize: 11,
                          fontWeight: 700,
                          color: COLORS[i % COLORS.length],
                          flexShrink: 0,
                        }}
                      >
                        {h.symbol.slice(0, 4)}
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <div style={{ fontSize: 15, fontWeight: 700, color: "#e6edf3" }}>{h.name}</div>
                        <div style={{ fontSize: 12, color: "#8b949e", marginTop: 2 }}>
                          {h.shares} 股 · 買入 ${h.buyPrice} · 現價 ${h.currentPrice}
                        </div>
                      </div>
                      <div style={{ textAlign: "right", flexShrink: 0 }}>
                        <div style={{ fontSize: 15, fontWeight: 700, color: "#e6edf3" }}>${formatTWD(value)}</div>
                        <div style={{ fontSize: 12, color: pnl >= 0 ? "#34d399" : "#f87171", marginTop: 2 }}>
                          {pnl >= 0 ? "+" : ""}${formatTWD(pnl)} ({formatPct(pnlPct)})
                        </div>
                      </div>
                      <div style={{ fontSize: 12, color: "#8b949e", flexShrink: 0, width: 40, textAlign: "right" }}>
                        {weight}%
                      </div>
                      <button
                        onClick={() => removeHolding(h.id)}
                        style={{
                          background: "none",
                          border: "1px solid #30363d",
                          borderRadius: 6,
                          color: "#8b949e",
                          width: 28,
                          height: 28,
                          cursor: "pointer",
                          fontSize: 14,
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          flexShrink: 0,
                        }}
                      >
                        ✕
                      </button>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Chart Tab */}
        {activeTab === "chart" && (
          <div style={{ background: "#161b22", border: "1px solid #21262d", borderRadius: 12, padding: 24 }}>
            <h3 style={{ margin: "0 0 20px", fontSize: 15, fontWeight: 600, color: "#e6edf3" }}>持倉配置比例</h3>
            {holdings.length === 0 ? (
              <div style={{ textAlign: "center", padding: 40, color: "#8b949e" }}>尚無持倉資料</div>
            ) : (
              <>
                <ResponsiveContainer width="100%" height={260}>
                  <PieChart>
                    <Pie data={pieData} cx="50%" cy="50%" innerRadius={70} outerRadius={110} paddingAngle={3} dataKey="value">
                      {pieData.map((_, i) => (
                        <Cell key={i} fill={COLORS[i % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip
                      formatter={(v) => [`$${formatTWD(v)}`, "市值"]}
                      contentStyle={{ background: "#161b22", border: "1px solid #30363d", borderRadius: 8 }}
                      labelStyle={{ color: "#e6edf3" }}
                    />
                  </PieChart>
                </ResponsiveContainer>
                <div style={{ display: "flex", flexWrap: "wrap", gap: 12, marginTop: 8 }}>
                  {holdings.map((h, i) => (
                    <div key={h.id} style={{ display: "flex", alignItems: "center", gap: 8 }}>
                      <div style={{ width: 10, height: 10, borderRadius: 2, background: COLORS[i % COLORS.length] }} />
                      <span style={{ fontSize: 13, color: "#8b949e" }}>
                        {h.symbol} — {((h.shares * h.currentPrice / totalValue) * 100).toFixed(1)}%
                      </span>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>
        )}

        {/* AI Tab */}
        {activeTab === "ai" && (
          <div style={{ background: "#161b22", border: "1px solid #21262d", borderRadius: 12, padding: 24, minHeight: 200 }}>
            <h3 style={{ margin: "0 0 16px", fontSize: 15, fontWeight: 600, color: "#e6edf3" }}>🤖 AI 投資分析</h3>
            {aiLoading && (
              <div style={{ display: "flex", alignItems: "center", gap: 12, color: "#8b949e" }}>
                <div style={{ width: 20, height: 20, border: "2px solid #4f8ef7", borderTopColor: "transparent", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />
                正在分析你的投資組合...
              </div>
            )}
            {!aiLoading && !aiAnalysis && (
              <div style={{ textAlign: "center", padding: 40, color: "#8b949e" }}>
                <div style={{ fontSize: 36, marginBottom: 12 }}>🤖</div>
                <div style={{ fontSize: 15, fontWeight: 600 }}>點擊「AI 分析」開始</div>
                <div style={{ fontSize: 13, marginTop: 6 }}>AI 會幫你評估持倉表現與風險</div>
              </div>
            )}
            {!aiLoading && aiAnalysis && (
              <div style={{ fontSize: 14, lineHeight: 1.8, color: "#c9d1d9", whiteSpace: "pre-wrap" }}>{aiAnalysis}</div>
            )}
          </div>
        )}
      </div>

      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
        input:focus { outline: none; border-color: #4f8ef7 !important; }
        * { transition: border-color 0.15s; }
      `}</style>
    </div>
  );
}
