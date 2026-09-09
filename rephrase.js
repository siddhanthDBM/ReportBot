const fs = require('fs');
const path = require('path');

const MODEL = 'nvidia/nemotron-3-ultra-550b-a55b:free';

function loadEnv() {
  const envPath = path.join(__dirname, '.env');
  const env = {};
  if (fs.existsSync(envPath)) {
    for (const line of fs.readFileSync(envPath, 'utf-8').split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const idx = trimmed.indexOf('=');
      if (idx === -1) continue;
      const key = trimmed.slice(0, idx).trim();
      let val = trimmed.slice(idx + 1).trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      env[key] = val;
    }
  }
  return env;
}

function stripCodeFence(text) {
  return text.trim()
    .replace(/^```(?:json)?\s*/i, '')
    .replace(/```\s*$/, '')
    .trim();
}

async function rephraseWeek(days, authorName) {
  const env = loadEnv();
  const apiKey = env.OPENROUTER_API_KEY || process.env.OPENROUTER_API_KEY;

  if (!apiKey) {
    console.warn('[rephrase] No OPENROUTER_API_KEY configured - using notes as typed.');
    return days;
  }

  const systemPrompt = `You are helping ${authorName} write a professional weekly work report for internal use at DBM (Discount Building Material). You will receive rough, informal daily notes grouped under section keys. Rewrite the notes under each key into 2-6 clear, professional bullet points suitable for a polished weekly report.

Rules:
- Keep every piece of factual content - never invent tasks, never drop any.
- Write in a natural, human, varied tone. Do not just lightly reword each sentence - restructure so it reads like an authored report, not a copy of the input.
- Bullets should read like completed accomplishments (action-verb style is fine, no need to say "I").
- Do not add commentary, extra sections, or extra keys beyond what was given.
- Return ONLY valid JSON: an object with the exact same keys as the input, each mapped to an array of rewritten bullet strings. No markdown, no code fences, no explanation text.`;

  const userPrompt = JSON.stringify(days, null, 2);
  const maxAttempts = 3;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    let response;
    try {
      response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: MODEL,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userPrompt },
          ],
          temperature: 0.6,
        }),
      });
    } catch (err) {
      console.warn(`[rephrase] Attempt ${attempt}/${maxAttempts}: network error calling OpenRouter:`, err.message);
      continue;
    }

    if (!response.ok) {
      const body = await response.text().catch(() => '');
      console.warn(`[rephrase] Attempt ${attempt}/${maxAttempts}: OpenRouter request failed:`, response.status, body.slice(0, 300));
      continue;
    }

    const json = await response.json();
    const content = json.choices && json.choices[0] && json.choices[0].message && json.choices[0].message.content;

    if (!content) {
      console.warn(`[rephrase] Attempt ${attempt}/${maxAttempts}: OpenRouter returned no content.`);
      continue;
    }

    try {
      const parsed = JSON.parse(stripCodeFence(content));
      for (const key of Object.keys(days)) {
        if (!Array.isArray(parsed[key]) || parsed[key].length === 0) {
          parsed[key] = days[key];
        }
      }
      return parsed;
    } catch (err) {
      console.warn(`[rephrase] Attempt ${attempt}/${maxAttempts}: could not parse rewritten JSON:`, err.message);
    }
  }

  console.warn('[rephrase] All attempts failed - using notes as typed.');
  return days;
}

module.exports = { rephraseWeek };
