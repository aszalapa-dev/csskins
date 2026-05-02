// Vercel serverless proxy for CSFloat API — keeps the API key server-side

export default async function handler(req, res) {
  const apiKey = process.env.CSFLOAT_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'CSFLOAT_KEY not configured' });
  }

  const { limit = '50', sort_by = 'lowest_price', type = 'buy_now', cursor } = req.query;

  const params = new URLSearchParams({ limit, sort_by, type });
  if (cursor) params.set('cursor', cursor);

  const upstream = 'https://csfloat.com/api/v1/listings?' + params.toString();

  try {
    const r = await fetch(upstream, {
      headers: {
        'Authorization': apiKey,
        'Accept': 'application/json',
      },
    });

    const body = await r.text();
    res.status(r.status)
       .setHeader('Content-Type', 'application/json')
       .send(body);
  } catch (err) {
    res.status(502).json({ error: 'upstream fetch failed', detail: err.message });
  }
}
