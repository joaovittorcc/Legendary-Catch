--!strict
-- Promo codes (typed in Settings). Each code works once per account. Codes are matched in
-- upper case; add new ones here (the server pays the coins, the client only types the text).

export type Code = {
	code: string,
	coins: number,
	expiresAt: number?, -- optional UTC os.time() deadline; nil = never expires
}

local LIST: { Code } = {
	{ code = "BEMVINDO", coins = 500 },
	{ code = "LENDARIO", coins = 1500 },
	{ code = "PESCADOR", coins = 750 },
}

local byCode: { [string]: Code } = {}
for _, c in LIST do
	byCode[c.code] = c
end

local Codes = {}

Codes.LIST = LIST

function Codes.find(text: string): Code?
	local clean = string.gsub(text, "%s+", "")
	local code = byCode[string.upper(clean)]
	if code and code.expiresAt and os.time() > code.expiresAt then
		return nil
	end
	return code
end

return Codes
