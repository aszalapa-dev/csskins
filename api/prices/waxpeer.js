export async function fetchPrice(market_hash_name) {
  const apiKey = process.env.WAXPEER_API_KEY;
  if (!apiKey) throw new Error('WAXPEER_API_KEY not configured');

  const params = new URLSearchParams({ api: apiKey, game: 'csgo', minified: '1' });
  const r = await fetch(`https://api.waxpeer.com/v1/prices?${params}`, {
    headers: { Accept: 'application/json' },
  });

  if (!r.ok) throw new Error(`Waxpeer responded with ${r.status}`);

  const data = await r.json();
  const item = Object.values(data.items ?? {}).find((i) => i.name === market_hash_name) ?? null;
  const priceRaw = item?.min ?? null;

  return {
    source: 'waxpeer',
    market_hash_name,
    price: priceRaw !== null ? priceRaw / 1000 : null,
    currency: 'USD',
    url: `https://waxpeer.com/csgo?search=${encodeURIComponent(market_hash_name)}`,
  };
}

export default async function handler(req, res) {
  const { market_hash_name } = req.query;
  if (!market_hash_name) return res.status(400).json({ error: 'market_hash_name query param is required' });

  try {
    return res.status(200).json(await fetchPrice(market_hash_name));
  } catch (err) {
    const status = err.message.includes('not configured') ? 500 : 502;
    return res.status(status).json({ error: err.message });
  }
}
