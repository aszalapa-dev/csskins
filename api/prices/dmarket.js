import crypto from 'crypto';

function buildDMarketHeaders(method, path, publicKey, privateKey) {
  const timestamp = Math.floor(Date.now() / 1000).toString();
  const stringToSign = method.toUpperCase() + path + timestamp;
  const signature = crypto
    .createHmac('sha256', privateKey)
    .update(stringToSign)
    .digest('hex');

  return {
    'X-Api-Key': publicKey,
    'X-Request-Sign': `dmar ed25519 ${signature}`,
    'X-Sign-Date': timestamp,
    Accept: 'application/json',
  };
}

export default async function handler(req, res) {
  const publicKey = process.env.DMARKET_PUBLIC_KEY;
  const privateKey = process.env.DMARKET_PRIVATE_KEY;

  if (!publicKey || !privateKey) {
    return res.status(500).json({ error: 'DMARKET_PUBLIC_KEY or DMARKET_PRIVATE_KEY not configured' });
  }

  const { market_hash_name } = req.query;
  if (!market_hash_name) {
    return res.status(400).json({ error: 'market_hash_name query param is required' });
  }

  const params = new URLSearchParams({
    gameId: 'a8db',
    title: market_hash_name,
    limit: '1',
    orderBy: 'price',
    orderDir: 'asc',
    currency: 'USD',
  });
  const path = `/exchange/v1/market/items?${params}`;

  try {
    const r = await fetch(`https://api.dmarket.com${path}`, {
      headers: buildDMarketHeaders('GET', path, publicKey, privateKey),
    });

    if (!r.ok) {
      return res.status(r.status).json({ error: `DMarket responded with ${r.status}` });
    }

    const data = await r.json();
    const item = data?.objects?.[0];
    const priceRaw = item?.price?.USD ?? null;

    return res.status(200).json({
      source: 'dmarket',
      market_hash_name,
      price: priceRaw !== null ? Number(priceRaw) / 100 : null,
      currency: 'USD',
      url: `https://dmarket.com/ingame-items/item-list/csgo-skins?title=${encodeURIComponent(market_hash_name)}`,
    });
  } catch (err) {
    return res.status(502).json({ error: 'Upstream fetch failed', detail: err.message });
  }
}
