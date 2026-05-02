export default async function handler(req, res) {
  const clientId = process.env.SKINPORT_CLIENT_ID;
  const clientSecret = process.env.SKINPORT_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    return res.status(500).json({ error: 'SKINPORT_CLIENT_ID or SKINPORT_CLIENT_SECRET not configured' });
  }

  const { market_hash_name } = req.query;
  if (!market_hash_name) {
    return res.status(400).json({ error: 'market_hash_name query param is required' });
  }

  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  const params = new URLSearchParams({ market_hash_name, app_id: '730' });

  try {
    const r = await fetch(`https://api.skinport.com/v1/items?${params}`, {
      headers: {
        Authorization: `Basic ${credentials}`,
        Accept: 'application/json',
      },
    });

    if (!r.ok) {
      return res.status(r.status).json({ error: `Skinport responded with ${r.status}` });
    }

    const data = await r.json();
    const item = Array.isArray(data) ? data[0] : null;

    return res.status(200).json({
      source: 'skinport',
      market_hash_name,
      price: item?.min_price ?? null,
      currency: 'USD',
      url: item ? `https://skinport.com/market?search=${encodeURIComponent(market_hash_name)}` : null,
    });
  } catch (err) {
    return res.status(502).json({ error: 'Upstream fetch failed', detail: err.message });
  }
}
