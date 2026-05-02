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
  const upstreamUrl = `https://api.skinport.com/v1/items?app_id=730&currency=EUR`;

  try {
    const r = await fetch(upstreamUrl, {
      headers: {
        Authorization: `Basic ${credentials}`,
        Accept: 'application/json',
      },
    });

    const body = await r.text();
    console.log('[skinport] url:', upstreamUrl);
    console.log('[skinport] status:', r.status);
    console.log('[skinport] body:', body);

    if (!r.ok) {
      let parsed;
      try { parsed = JSON.parse(body); } catch { parsed = body; }
      return res.status(r.status).json({ error: `Skinport responded with ${r.status}`, skinport_error: parsed });
    }

    const data = JSON.parse(body);
    const item = Array.isArray(data) ? data.find((i) => i.market_hash_name === market_hash_name) ?? null : null;

    return res.status(200).json({
      source: 'skinport',
      market_hash_name,
      price: item?.min_price ?? null,
      currency: 'EUR',
      url: item ? `https://skinport.com/market?search=${encodeURIComponent(market_hash_name)}` : null,
    });
  } catch (err) {
    return res.status(502).json({ error: 'Upstream fetch failed', detail: err.message });
  }
}
