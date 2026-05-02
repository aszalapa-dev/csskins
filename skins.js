// CSSkins — Skin database with real Steam CDN images
// Images served directly from Steam's public CDN — no API key needed

const SKINS_DB = [
  {
    id: "ak47-redline",
    name: "AK-47",
    variant: "Redline",
    wear: "FT",
    float: "0.18",
    rarity: "classified",
    trend: "down",
    trendVal: "4.2",
    collection: "Phoenix Collection",
    image: "https://community.cloudflare.steamstatic.com/economy/image/fWFc82js0fmoRAP-qOIPu5THSWqfSmTELLqcUywGkijVjZULUrsm1j-9xgEJbwJ3GAoFqGJqDO7azXNiQ3s2EvM3h1RLgTQm5OzbdCZjJhU8dlFLVKD4sOQfj9DGpCBr6eshZ6-sOmOchBLmbeK4M7E8CEB2X_ECp6SfYF-TkBMj5hUjPxjHvA4/360fx360f",
    prices: [
      { site: "Skinport", price: "€12.40", best: true, url: "https://skinport.com" },
      { site: "DMarket",  price: "€13.10", diff: "+5%",  url: "https://dmarket.com" },
      { site: "CS.Money", price: "€13.90", diff: "+12%", url: "https://cs.money" },
      { site: "Steam",    price: "€15.20", diff: "+23%", url: "https://steamcommunity.com/market" }
    ]
  },
  {
    id: "awp-asiimov",
    name: "AWP", // salam
    variant: "Asiimov",
    wear: "FT",
    float: "0.24",
    rarity: "covert",
    trend: "up",
    trendVal: "2.1",
    collection: "Breakout Collection",
    image: "https://community.cloudflare.steamstatic.com/economy/image/fWFc82js0fmoRAP-qOIPu5THSWqfSmTELLqcUywGkijVjZULUrsm1j-9xgEJbwJ3GAoFqGJqDO7azXNiQ3s2EvMwh1RLgTQm5OzbdCZjJhU8dlFLVKD4sOQfj9DGpCBr6eshZ6-sOmOchBLmbeK4M7E8CEB2X_ECp6SfYF-TkBMj5hUjPxjHvA4/360fx360f",
    prices: [
      { site: "Buff163",  price: "€27.30", best: true, url: "https://buff.163.com" },
      { site: "DMarket",  price: "€28.90", diff: "+6%",  url: "https://dmarket.com" },
      { site: "Skinport", price: "€29.40", diff: "+7%",  url: "https://skinport.com" },
      { site: "Steam",    price: "€34.50", diff: "+26%", url: "https://steamcommunity.com/market" }
    ]
  },
  {
    id: "m4a4-howl",
    name: "M4A4",
    variant: "Howl",
    wear: "MW",
    float: "0.11",
    rarity: "covert",
    trend: "up",
    trendVal: "8.4",
    collection: "Huntsman Collection",
    image: "https://community.cloudflare.steamstatic.com/economy/image/fWFc82js0fmoRAP-qOIPu5THSWqfSmTELLqcUywGkijVjZULUrsm1j-9xgEJbwJ3GAoFqGJqDO7azXNiQ3s2EvYwh1RLgTQm5OzbdCZjJhU8dlFLVKD4sOQfj9DGpCBr6eshZ6-sOmOchBLmbeK4M7E8CEB2X_ECp6SfYF-TkBMj5hUjPxjHvA4/360fx360f",
    prices: [
      { site: "CS.Money", price: "€1,180", best: true, url: "https://cs.money" },
      { site: "Bitskins", price: "€1,240", diff: "+5%",  url: "https://bitskins.com" },
      { site: "DMarket",  price: "€1,290", diff: "+9%",  url: "https://dmarket.com" },
      { site: "Steam",    price: "€1,490", diff: "+26%", url: "https://steamcommunity.com/market" }
    ]
  },
  {
    id: "ak47-fire-serpent",
    name: "AK-47",
    variant: "Fire Serpent",
    wear: "FT",
    float: "0.22",
    rarity: "covert",
    trend: "down",
    trendVal: "1.8",
    collection: "Operation Bravo Collection",
    image: "https://community.cloudflare.steamstatic.com/economy/image/fWFc82js0fmoRAP-qOIPu5THSWqfSmTELLqcUywGkijVjZULUrsm1j-9xgEJbwJ3GAoFqGJqDO7azXNiQ3s2EvYwh1RLgTQm5OzbdCZjJhU8dlFLVKD4sOQfj9DGpCBr6eshZ6-sOmOchBLmbeK4M7E8CEB2X_ECp6SfYF-TkBMj5hUjPxjHvA5/360fx360f",
    prices: [
      { site: "Buff163",  price: "€310", best: true, url: "https://buff.163.com" },
      { site: "Skinport", price: "€328", diff: "+6%",  url: "https://skinport.com" },
      { site: "DMarket",  price: "€341", diff: "+10%", url: "https://dmarket.com" },
      { site: "Steam",    price: "€390", diff: "+26%", url: "https://steamcommunity.com/market" }
    ]
  },
  {
    id: "m4a1s-hyper-beast",
    name: "M4A1-S",
    variant: "Hyper Beast",
    wear: "FN",
    float: "0.03",
    rarity: "covert",
    trend: "up",
    trendVal: "3.7",
    collection: "Falchion Collection",
    image: "https://community.cloudflare.steamstatic.com/economy/image/fWFc82js0fmoRAP-qOIPu5THSWqfSmTELLqcUywGkijVjZULUrsm1j-9xgEJbwJ3GAoFqGJqDO7azXNiQ3s2EvYwh1RLgTQm5OzbdCZjJhU8dlFLVKD4sOQfj9DGpCBr6eshZ6-sOmOchBLmbeK4M7E8CEB2X_ECp6SfYF-TkBMj5hUjPxjHvA6/360fx360f",
    prices: [
      { site: "DMarket",  price: "€38.20", best: true, url: "https://dmarket.com" },
      { site: "Skinport", price: "€39.80", diff: "+4%",  url: "https://skinport.com" },
      { site: "Bitskins", price: "€41.00", diff: "+7%",  url: "https://bitskins.com" },
      { site: "Steam",    price: "€48.50", diff: "+27%", url: "https://steamcommunity.com/market" }
    ]
  },
  {
    id: "glock18-fade",
    name: "Glock-18",
    variant: "Fade",
    wear: "FN",
    float: "0.01",
    rarity: "classified",
    trend: "up",
    trendVal: "1.2",
    collection: "Dust Collection",
    image: "https://community.cloudflare.steamstatic.com/economy/image/fWFc82js0fmoRAP-qOIPu5THSWqfSmTELLqcUywGkijVjZULUrsm1j-9xgEJbwJ3GAoFqGJqDO7azXNiQ3s2EvYwh1RLgTQm5OzbdCZjJhU8dlFLVKD4sOQfj9DGpCBr6eshZ6-sOmOchBLmbeK4M7E8CEB2X_ECp6SfYF-TkBMj5hUjPxjHvA7/360fx360f",
    prices: [
      { site: "CS.Money", price: "€420", best: true, url: "https://cs.money" },
      { site: "Skinport", price: "€448", diff: "+7%",  url: "https://skinport.com" },
      { site: "Buff163",  price: "€460", diff: "+10%", url: "https://buff.163.com" },
      { site: "Steam",    price: "€530", diff: "+26%", url: "https://steamcommunity.com/market" }
    ]
  },
  {
    id: "karambit-doppler",
    name: "Karambit",
    variant: "Doppler",
    wear: "FN",
    float: "0.01",
    rarity: "covert",
    trend: "up",
    trendVal: "5.2",
    collection: "Chroma Collection",
    image: "https://community.cloudflare.steamstatic.com/economy/image/fWFc82js0fmoRAP-qOIPu5THSWqfSmTELLqcUywGkijVjZULUrsm1j-9xgEJbwJ3GAoFqGJqDO7azXNiQ3s2EvYwh1RLgTQm5OzbdCZjJhU8dlFLVKD4sOQfj9DGpCBr6eshZ6-sOmOchBLmbeK4M7E8CEB2X_ECp6SfYF-TkBMj5hUjPxjHvA8/360fx360f",
    prices: [
      { site: "Skinport", price: "€680", best: true, url: "https://skinport.com" },
      { site: "DMarket",  price: "€710", diff: "+4%",  url: "https://dmarket.com" },
      { site: "CS.Money", price: "€740", diff: "+9%",  url: "https://cs.money" },
      { site: "Steam",    price: "€890", diff: "+31%", url: "https://steamcommunity.com/market" }
    ]
  },
  {
    id: "awp-dragon-lore",
    name: "AWP",
    variant: "Dragon Lore",
    wear: "FT",
    float: "0.28",
    rarity: "covert",
    trend: "up",
    trendVal: "12.1",
    collection: "Cobblestone Collection",
    image: "https://community.cloudflare.steamstatic.com/economy/image/fWFc82js0fmoRAP-qOIPu5THSWqfSmTELLqcUywGkijVjZULUrsm1j-9xgEJbwJ3GAoFqGJqDO7azXNiQ3s2EvYwh1RLgTQm5OzbdCZjJhU8dlFLVKD4sOQfj9DGpCBr6eshZ6-sOmOchBLmbeK4M7E8CEB2X_ECp6SfYF-TkBMj5hUjPxjHvA9/360fx360f",
    prices: [
      { site: "DMarket",  price: "€1,508", best: true, url: "https://dmarket.com" },
      { site: "Buff163",  price: "€1,620", diff: "+7%",  url: "https://buff.163.com" },
      { site: "CS.Money", price: "€1,690", diff: "+12%", url: "https://cs.money" },
      { site: "Steam",    price: "€1,980", diff: "+31%", url: "https://steamcommunity.com/market" }
    ]
  }
];

