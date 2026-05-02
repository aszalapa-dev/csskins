export default async function handler(req, res) {
  const apiKey = process.env.CSFLOAT_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'CSFLOAT_API_KEY not configured' });
  }

  const { market_hash_name } = req.query;
  if (!market_hash_name) {
    return res.status(400).json({ error: 'market_hash_name query param is required' });
  }

  const params = new URLSearchParams({
    market_hash_name,
    sort_by: 'lowest_price',
    type: 'buy_now',
    limit: '1',
  });

  try {
    const r = await fetch(`https://csfloat.com/api/v1/listings?${params}`, {
      headers: {
        Authorization: apiKey,
        Accept: 'application/json',
      },
    });

    if (!r.ok) {
      return res.status(r.status).json({ error: `CSFloat responded with ${r.status}` });
    }

    const data = await r.json();
    const item = data?.data?.[0];
    const priceRaw = item?.price ?? null;

    return res.status(200).json({
      source: 'csfloat',
      market_hash_name,
      price: priceRaw !== null ? priceRaw / 100 : null,
      currency: 'USD',
      url: `https://csfloat.com/buy?market_hash_name=${encodeURIComponent(market_hash_name)}`,
    });
  } catch (err) {
    return res.status(502).json({ error: 'Upstream fetch failed', detail: err.message });
  }
}
