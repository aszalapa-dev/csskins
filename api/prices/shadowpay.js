export default async function handler(req, res) {
  const apiKey = process.env.SHADOWPAY_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'SHADOWPAY_API_KEY not configured' });
  }

  const { market_hash_name } = req.query;
  if (!market_hash_name) {
    return res.status(400).json({ error: 'market_hash_name query param is required' });
  }

  const params = new URLSearchParams({
    steam_app_id: '730',
    search: market_hash_name,
  });

  try {
    const r = await fetch(`https://api.shadowpay.com/api/v2/user/items?${params}`, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        Accept: 'application/json',
      },
    });

    if (!r.ok) {
      return res.status(r.status).json({ error: `Shadowpay responded with ${r.status}` });
    }

    const data = await r.json();
    const item = data?.data?.[0];

    return res.status(200).json({
      source: 'shadowpay',
      market_hash_name,
      price: item?.price ?? null,
      currency: 'USD',
      url: `https://shadowpay.com/csgo-items?search=${encodeURIComponent(market_hash_name)}`,
    });
  } catch (err) {
    return res.status(502).json({ error: 'Upstream fetch failed', detail: err.message });
  }
}
