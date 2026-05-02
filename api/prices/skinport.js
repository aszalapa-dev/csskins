export async function fetchPrice(market_hash_name) {
  const clientId = process.env.SKINPORT_CLIENT_ID;
  const clientSecret = process.env.SKINPORT_CLIENT_SECRET;

  if (!clientId || !clientSecret) throw new Error('SKINPORT_CLIENT_ID or SKINPORT_CLIENT_SECRET not configured');

  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  const upstreamUrl = `https://api.skinport.com/v1/items?app_id=730&currency=EUR`;

  const r = await fetch(upstreamUrl, {
    headers: { Authorization: `Basic ${credentials}`, Accept: 'application/json' },
  });

  const body = await r.text();
  console.log('[skinport] status:', r.status);
  console.log('[skinport] body:', body);

  if (!r.ok) {
    let parsed;
    try { parsed = JSON.parse(body); } catch { parsed = body; }
    throw Object.assign(new Error(`Skinport responded with ${r.status}`), { skinport_error: parsed });
  }

  const data = JSON.parse(body);
  const item = Array.isArray(data) ? data.find((i) => i.market_hash_name === market_hash_name) ?? null : null;

  return {
    source: 'skinport',
    market_hash_name,
    price: item?.min_price ?? null,
    currency: 'EUR',
    url: item ? `https://skinport.com/market?search=${encodeURIComponent(market_hash_name)}` : null,
  };
}

export default async function handler(req, res) {
  const { market_hash_name } = req.query;
  if (!market_hash_name) return res.status(400).json({ error: 'market_hash_name query param is required' });

  try {
    return res.status(200).json(await fetchPrice(market_hash_name));
  } catch (err) {
    const status = err.message.includes('not configured') ? 500 : 502;
    return res.status(status).json({ error: err.message, skinport_error: err.skinport_error });
  }
}
