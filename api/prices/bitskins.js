export async function fetchPrice(market_hash_name) {
  const apiKey = process.env.BITSKINS_API_KEY;
  if (!apiKey) throw new Error('BITSKINS_API_KEY not configured');

  const r = await fetch('https://api.bitskins.com/market/search/730', {
    method: 'POST',
    headers: { 'x-apikey': apiKey, 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({ limit: 5, offset: 0, where: { skin_name: market_hash_name } }),
  });

  const body = await r.text();
  if (!r.ok) {
    let parsed;
    try { parsed = JSON.parse(body); } catch { parsed = body; }
    throw Object.assign(new Error(`BitSkins responded with ${r.status}`), { bitskins_error: parsed });
  }

  const data = JSON.parse(body);
  const item = data?.list?.[0];

  return {
    source: 'bitskins',
    market_hash_name,
    price: item?.price ?? null,
    currency: 'USD',
    url: `https://bitskins.com/market/cs2?market_hash_name=${encodeURIComponent(market_hash_name)}`,
  };
}

export default async function handler(req, res) {
  const { market_hash_name } = req.query;
  if (!market_hash_name) return res.status(400).json({ error: 'market_hash_name query param is required' });

  try {
    return res.status(200).json(await fetchPrice(market_hash_name));
  } catch (err) {
    const status = err.message.includes('not configured') ? 500 : 502;
    return res.status(status).json({ error: err.message, bitskins_error: err.bitskins_error });
  }
}
