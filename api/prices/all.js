import { fetchPrice as fetchSkinport } from './skinport.js';
import { fetchPrice as fetchCsfloat } from './csfloat.js';
import { fetchPrice as fetchDmarket } from './dmarket.js';
import { fetchPrice as fetchShadowpay } from './shadowpay.js';
import { fetchPrice as fetchWaxpeer } from './waxpeer.js';
import { fetchPrice as fetchBitskins } from './bitskins.js';

const FETCHERS = [
  fetchSkinport,
  fetchCsfloat,
  fetchDmarket,
  fetchShadowpay,
  fetchWaxpeer,
  fetchBitskins,
];

export default async function handler(req, res) {
  const { market_hash_name } = req.query;
  if (!market_hash_name) {
    return res.status(400).json({ error: 'market_hash_name query param is required' });
  }

  const results = await Promise.allSettled(FETCHERS.map((fn) => fn(market_hash_name)));

  const prices = results
    .map((result) => {
      if (result.status === 'fulfilled') {
        const { source, price, currency, url } = result.value;
        return { source, price, currency, url };
      }
      return null;
    })
    .filter((p) => p !== null && p.price !== null);

  return res.status(200).json({ market_hash_name, prices });
}
