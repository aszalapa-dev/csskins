export default async function handler(req, res) {
  const apiKey = process.env.WAXPEER_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'WAXPEER_API_KEY not configured' });
  }

  const { market_hash_name } = req.query;
  if (!market_hash_name) {
    return res.status(400).json({ error: 'market_hash_name query param is required' });
  }

  const params = new URLSearchParams({
    api: apiKey,
    game: 'csgo',
    minified: '1',
  });

  try {
    const r = await fetch(`https://api.waxpeer.com/v1/prices?${params}`, {
      headers: { Accept: 'application/json' },
    });

    if (!r.ok) {
      return res.status(r.status).json({ error: `Waxpeer responded with ${r.status}` });
    }

    const data = await r.json();
    const item = Object.values(data).find((i) => i?.name === market_hash_name) ?? null;
    const priceRaw = item?.min ?? null;

    return res.status(200).json({
      source: 'waxpeer',
      market_hash_name,
      price: priceRaw !== null ? priceRaw / 1000 : null,
      currency: 'USD',
      url: `https://waxpeer.com/csgo?search=${encodeURIComponent(market_hash_name)}`,
    });
  } catch (err) {
    return res.status(502).json({ error: 'Upstream fetch failed', detail: err.message });
  }
}
