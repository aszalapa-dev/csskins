const cache = new Map();
const CACHE_TTL_MS = 10 * 60 * 1000;

export async function fetchPrice(market_hash_name) {
  const apiKey = process.env.CSFLOAT_API_KEY;
  if (!apiKey) throw new Error('CSFLOAT_API_KEY not configured');

  const cached = cache.get(market_hash_name);
  if (cached && Date.now() - cached.ts < CACHE_TTL_MS) return cached.data;

  const params = new URLSearchParams({ market_hash_name, limit: '1', sort_by: 'lowest_price', type: 'buy_now' });
  const r = await fetch(`https://csfloat.com/api/v1/listings?${params}`, {
    headers: { Authorization: apiKey, Accept: 'application/json' },
  });

  if (!r.ok) {
    const errBody = await r.text();
    throw Object.assign(new Error(`CSFloat responded with ${r.status}`), { csfloat_error: errBody });
  }

  const data = await r.json();
  const item = data?.data?.[0];
  const priceRaw = item?.price ?? null;

  const result = {
    source: 'csfloat',
    market_hash_name,
    price: priceRaw !== null ? priceRaw / 100 : null,
    currency: 'USD',
    url: `https://csfloat.com/buy?market_hash_name=${encodeURIComponent(market_hash_name)}`,
  };

  cache.set(market_hash_name, { ts: Date.now(), data: result });
  return result;
}

export default async function handler(req, res) {
  const { market_hash_name } = req.query;
  if (!market_hash_name) return res.status(400).json({ error: 'market_hash_name query param is required' });

  try {
    const result = await fetchPrice(market_hash_name);
    res.setHeader('Cache-Control', 's-maxage=600, stale-while-revalidate=300');
    return res.status(200).json(result);
  } catch (err) {
    const status = err.message.includes('not configured') ? 500 : 502;
    return res.status(status).json({ error: err.message, csfloat_error: err.csfloat_error });
  }
}
