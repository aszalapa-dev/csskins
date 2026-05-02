export async function fetchPrice(market_hash_name) {
  const apiKey = process.env.SHADOWPAY_API_KEY;
  if (!apiKey) throw new Error('SHADOWPAY_API_KEY not configured');

  const params = new URLSearchParams({ steam_app_id: '730', search: market_hash_name });
  const r = await fetch(`https://api.shadowpay.com/api/v2/user/items?${params}`, {
    headers: { Authorization: `Bearer ${apiKey}`, Accept: 'application/json' },
  });

  if (!r.ok) throw new Error(`Shadowpay responded with ${r.status}`);

  const data = await r.json();
  const item = data?.data?.[0];

  return {
    source: 'shadowpay',
    market_hash_name,
    price: item?.price ?? null,
    currency: 'USD',
    url: `https://shadowpay.com/csgo-items?search=${encodeURIComponent(market_hash_name)}`,
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
