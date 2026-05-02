const SOURCES = ['skinport', 'csfloat', 'dmarket', 'shadowpay', 'waxpeer', 'bitskins'];

async function fetchSource(baseUrl, source, market_hash_name) {
  const url = `${baseUrl}/api/prices/${source}?market_hash_name=${encodeURIComponent(market_hash_name)}`;
  const r = await fetch(url);
  if (!r.ok) throw new Error(`${source} responded with ${r.status}`);
  return r.json();
}

export default async function handler(req, res) {
  const { market_hash_name } = req.query;
  if (!market_hash_name) {
    return res.status(400).json({ error: 'market_hash_name query param is required' });
  }

  const baseUrl = process.env.VERCEL_URL
    ? `https://${process.env.VERCEL_URL}`
    : 'http://localhost:3000';

  const results = await Promise.allSettled(
    SOURCES.map((source) => fetchSource(baseUrl, source, market_hash_name))
  );

  const prices = results
    .map((result, i) => {
      if (result.status === 'fulfilled') {
        const { source, price, currency, url } = result.value;
        return { source, price, currency, url };
      }
      return { source: SOURCES[i], price: null, currency: null, url: null, error: result.reason?.message };
    })
    .filter((p) => p.price !== null);

  return res.status(200).json({ market_hash_name, prices });
}
