export default async function handler(req, res) {
  const apiKey = process.env.BITSKINS_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'BITSKINS_API_KEY not configured' });
  }

  const { market_hash_name } = req.query;
  if (!market_hash_name) {
    return res.status(400).json({ error: 'market_hash_name query param is required' });
  }

  const params = new URLSearchParams({
    market_hash_name,
    skin_search: market_hash_name,
    per_page: '1',
    page: '1',
  });

  try {
    const r = await fetch(`https://api.bitskins.com/market/insell/730?${params}`, {
      headers: {
        'X-Apikey': apiKey,
        Accept: 'application/json',
      },
    });

    if (!r.ok) {
      return res.status(r.status).json({ error: `BitSkins responded with ${r.status}` });
    }

    const data = await r.json();
    const item = data?.list?.[0];

    return res.status(200).json({
      source: 'bitskins',
      market_hash_name,
      price: item?.price ?? null,
      currency: 'USD',
      url: `https://bitskins.com/market/cs2?market_hash_name=${encodeURIComponent(market_hash_name)}`,
    });
  } catch (err) {
    return res.status(502).json({ error: 'Upstream fetch failed', detail: err.message });
  }
}
