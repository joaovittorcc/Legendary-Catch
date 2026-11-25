--!strict
--[[
	SfxKit.luau
	Suggested Studio path: ReplicatedStorage/Shared/Vfx/SfxKit
	Rojo path: src/shared/Vfx/SfxKit.luau

	Integration:
	- Client-only audio manager using SoundService + SoundGroups (SFX, Music, UI).
	- Call SfxKit.play("bite_rare", { pitch = 1.05 }) for 2D SFX/UI sounds.
	- Call SfxKit.playAt("water_splash", position, { volume = 0.8 }) for 3D positional sounds
	  with pooled emitters and RollOffMaxDistance.
	- Call SfxKit.setRegionMusic("hub" | "pier" | "training" | "aquarium" | "expedition" | "event")
	  to smoothly crossfade background music.
	- All entries in SOUND_IDS default to "rbxassetid://0 -- TROCAR: ..." and silently
	  no-op (no errors, no warning spam) until real asset IDs are filled in.
	- Assumption: If your game already stores Sound objects in ReplicatedStorage.Audio,
	  you can either paste their SoundId into SOUND_IDS or call SfxKit.registerId(name, id).
]]

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

export type SoundCategory = "SFX" | "Music" | "UI"
export type MusicRegion = "hub" | "pier" | "training" | "aquarium" | "expedition" | "event"

export type PlayOptions = {
	volume: number?,
	pitch: number?,
	pitchJitter: number?,
	cooldown: number?,
	rollOffMin: number?,
	rollOffMax: number?,
	looped: boolean?,
	category: SoundCategory?,
	parent: Instance?,
}

type SoundMeta = {
	category: SoundCategory,
	volume: number,
	cooldown: number,
	pitchJitter: number,
	rollOffMax: number,
}

local SfxKit = {}

-- ============================================================================
-- CENTRAL SOUND ID CATALOG (replace "0" with real uploaded Roblox SoundIds)
-- ============================================================================

local SOUND_IDS: { [string]: string } = {
	-- Fishing loop
	rod_equip = "rbxassetid://0 -- TROCAR: som leve de madeira/vara de pesca sendo equipada",
	charge_loop = "rbxassetid://0 -- TROCAR: zumbido mágico suave crescente de carga de energia (loop)",
	charge_perfect_ding = "rbxassetid://0 -- TROCAR: sino cristalino agudo e satisfatório de acerto perfeito",
	cast_whoosh = "rbxassetid://0 -- TROCAR: whoosh rápido de linha e vara cortando o ar",
	water_splash_small = "rbxassetid://0 -- TROCAR: plop/splash pequeno de boia caindo na água",
	water_splash_big = "rbxassetid://0 -- TROCAR: splash encorpado e alegre de arremesso forte na água",
	bobber_dip = "rbxassetid://0 -- TROCAR: borbulho curto e suave de boia afundando",
	bite_common = "rbxassetid://0 -- TROCAR: alerta curto e amigável de fisgada comum",
	bite_uncommon = "rbxassetid://0 -- TROCAR: alerta borbulhante com brilho azul para fisgada incomum",
	bite_rare = "rbxassetid://0 -- TROCAR: alerta mágico com acorde roxo para fisgada rara",
	bite_epic = "rbxassetid://0 -- TROCAR: alerta dramático e energético para fisgada épica",
	bite_legendary = "rbxassetid://0 -- TROCAR: trombeta/chime dourado épico e marcante para fisgada lendária",

	-- Minigames
	minigame_hit = "rbxassetid://0 -- TROCAR: clique musical pop satisfatório ao acertar minigame",
	minigame_perfect = "rbxassetid://0 -- TROCAR: chime brilhante com harmonia para acerto PERFEITO",
	minigame_miss = "rbxassetid://0 -- TROCAR: som abafado suave de erro (não assustador)",
	minigame_win = "rbxassetid://0 -- TROCAR: fanfarra curta alegre de vitória no minigame",
	minigame_lose = "rbxassetid://0 -- TROCAR: som descendente suave de peixe escapando na água",

	-- Catch reveal & styles
	reveal_common = "rbxassetid://0 -- TROCAR: brilho curto de revelação comum (<= 1.5s)",
	reveal_uncommon = "rbxassetid://0 -- TROCAR: arpejo aquático de revelação incomum",
	reveal_rare = "rbxassetid://0 -- TROCAR: acorde místico cintilante de revelação rara",
	reveal_epic = "rbxassetid://0 -- TROCAR: explosão mágica vibrante de revelação épica",
	reveal_legendary = "rbxassetid://0 -- TROCAR: fanfarra cinematográfica grandiosa e alegre de revelação lendária",
	reveal_electric = "rbxassetid://0 -- TROCAR: estalo elétrico estilizado e energético para revelação elétrica",
	reveal_cosmic = "rbxassetid://0 -- TROCAR: coro estelar cintilante para revelação cósmica",
	reveal_magma = "rbxassetid://0 -- TROCAR: rugido vulcânico estilizado (kid-friendly) para revelação magma",
	reveal_abyss = "rbxassetid://0 -- TROCAR: ressonância profunda submarina mística para revelação abismo",
	reveal_celestial = "rbxassetid://0 -- TROCAR: harpa celestial e sinos dourados para revelação celestial",
	new_discovery = "rbxassetid://0 -- TROCAR: jingle festivo curto de NOVA DESCOBERTA",

	-- World, portals, aquarium, training, ocean events
	portal_ambient = "rbxassetid://0 -- TROCAR: sussurro mágico suave de vórtice de portal (loop)",
	portal_teleport = "rbxassetid://0 -- TROCAR: whoosh cristalino de teletransporte mágico",
	aquarium_bubbles = "rbxassetid://0 -- TROCAR: bolhas calmas de aquário",
	aquarium_coin_pop = "rbxassetid://0 -- TROCAR: plim suave de moeda saindo do aquário",
	aquarium_level_up = "rbxassetid://0 -- TROCAR: acorde aquático ascendente de upgrade de tanque",
	training_tick = "rbxassetid://0 -- TROCAR: pulso rítmico suave de treino concluído",
	training_level_up = "rbxassetid://0 -- TROCAR: fanfarra ascendente cristalina de subida de nível de treino",
	ocean_thunder_soft = "rbxassetid://0 -- TROCAR: trovão distante e suave (não assustador) para evento",
	ocean_event_start = "rbxassetid://0 -- TROCAR: chamada mágica atmosférica de início de evento do oceano",

	-- UI & collection
	ui_hover = "rbxassetid://0 -- TROCAR: tick ultra suave de hover em botão",
	ui_click = "rbxassetid://0 -- TROCAR: pop tátil agradável de clique em botão",
	ui_coin = "rbxassetid://0 -- TROCAR: tilintar alegre de moeda no HUD",
	ui_toast = "rbxassetid://0 -- TROCAR: pop suave de notificação/toast",
	shop_buy = "rbxassetid://0 -- TROCAR: som de caixa registradora mágica + confete ao comprar",
	collection_unlock = "rbxassetid://0 -- TROCAR: brilho mágico de carta/silhueta revelada no bestiário",

	-- Regional ambient music (looped, crossfaded)
	music_hub = "rbxassetid://0 -- TROCAR: trilha calma, alegre e mágica de ilha-hub (loop)",
	music_pier = "rbxassetid://0 -- TROCAR: trilha relaxante costeira com brisa do mar no píer (loop)",
	music_training = "rbxassetid://0 -- TROCAR: trilha meditativa e motivadora de ilhas de treino (loop)",
	music_aquarium = "rbxassetid://0 -- TROCAR: trilha aquática cristalina e suave de aquário (loop)",
	music_expedition = "rbxassetid://0 -- TROCAR: trilha de aventura vibrante para ilhas de expedição (loop)",
	music_event = "rbxassetid://0 -- TROCAR: trilha épica e divertida de evento especial do oceano (loop)",
}

SfxKit.SOUND_IDS = SOUND_IDS

local DEFAULT_META: SoundMeta = {
	category = "SFX",
	volume = 0.65,
	cooldown = 0.06,
	pitchJitter = 0.08,
	rollOffMax = 95,
}

local SOUND_META: { [string]: SoundMeta } = {
	charge_perfect_ding = {
		category = "SFX",
		volume = 0.85,
		cooldown = 0.12,
		pitchJitter = 0.04,
		rollOffMax = 80,
	},
	water_splash_small = {
		category = "SFX",
		volume = 0.6,
		cooldown = 0.08,
		pitchJitter = 0.08,
		rollOffMax = 85,
	},
	water_splash_big = {
		category = "SFX",
		volume = 0.8,
		cooldown = 0.10,
		pitchJitter = 0.08,
		rollOffMax = 110,
	},
	bite_legendary = {
		category = "SFX",
		volume = 0.95,
		cooldown = 0.25,
		pitchJitter = 0.03,
		rollOffMax = 120,
	},
	minigame_hit = {
		category = "UI",
		volume = 0.65,
		cooldown = 0.05,
		pitchJitter = 0.06,
		rollOffMax = 70,
	},
	minigame_perfect = {
		category = "UI",
		volume = 0.8,
		cooldown = 0.08,
		pitchJitter = 0.04,
		rollOffMax = 70,
	},
	minigame_miss = {
		category = "UI",
		volume = 0.55,
		cooldown = 0.12,
		pitchJitter = 0.05,
		rollOffMax = 70,
	},
	ui_hover = {
		category = "UI",
		volume = 0.28,
		cooldown = 0.05,
		pitchJitter = 0.06,
		rollOffMax = 50,
	},
	ui_click = {
		category = "UI",
		volume = 0.5,
		cooldown = 0.04,
		pitchJitter = 0.07,
		rollOffMax = 50,
	},
	ui_coin = {
		category = "UI",
		volume = 0.55,
		cooldown = 0.05,
		pitchJitter = 0.08,
		rollOffMax = 50,
	},
	ui_toast = {
		category = "UI",
		volume = 0.5,
		cooldown = 0.15,
		pitchJitter = 0.05,
		rollOffMax = 50,
	},
	shop_buy = {
		category = "UI",
		volume = 0.78,
		cooldown = 0.20,
		pitchJitter = 0.04,
		rollOffMax = 60,
	},
	collection_unlock = {
		category = "UI",
		volume = 0.75,
		cooldown = 0.20,
		pitchJitter = 0.04,
		rollOffMax = 60,
	},
	training_tick = {
		category = "SFX",
		volume = 0.5,
		cooldown = 0.12,
		pitchJitter = 0.08,
		rollOffMax = 80,
	},
	aquarium_coin_pop = {
		category = "SFX",
		volume = 0.5,
		cooldown = 0.10,
		pitchJitter = 0.08,
		rollOffMax = 75,
	},
	portal_teleport = {
		category = "SFX",
		volume = 0.8,
		cooldown = 0.30,
		pitchJitter = 0.06,
		rollOffMax = 100,
	},
}

local REGION_TO_SOUND: { [string]: string } = {
	hub = "music_hub",
	pier = "music_pier",
	training = "music_training",
	aquarium = "music_aquarium",
	expedition = "music_expedition",
	event = "music_event",
}

-- ============================================================================
-- INTERNAL STATE, SOUNDGROUPS & POOLS
-- ============================================================================

local MAX_2D_POOL = 24
local MAX_3D_POOL = 18

local initialized = false
local rng = Random.new()
local lastPlayedAt: { [string]: number } = {}
-- Keyed by plain string: luau-lsp 1.70 loses string-literal unions on table keys.
local soundGroups: { [string]: SoundGroup } = {}

local folder2D: Folder? = nil
local folder3D: Folder? = nil
local pool2D: { Sound } = {}
local pool3D: { { part: Part, sound: Sound } } = {}

-- Music crossfade state
local activeMusicSound: Sound? = nil
local activeMusicRegion: string? = nil
local activeMusicTweens: { Tween } = {}
local musicBaseVolume = 0.42

-- Extract clean numeric asset ID; returns nil when placeholder ("0") or empty
local function resolveSoundAsset(name: string): string?
	local raw = SOUND_IDS[name]
	if typeof(raw) ~= "string" or raw == "" then
		return nil
	end
	local digits = string.match(raw, "rbxassetid://(%d+)")
	if not digits or digits == "0" then
		-- Also allow rbxasset:// local built-in paths if a developer sets one
		if string.sub(raw, 1, 11) == "rbxasset://" then
			return raw
		end
		return nil
	end
	return "rbxassetid://" .. digits
end

local function ensureGroup(name: SoundCategory, defaultVolume: number): SoundGroup
	local groupName = "LegendaryCatch_" .. name
	local existing = SoundService:FindFirstChild(groupName)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = groupName
	group.Volume = defaultVolume
	group.Parent = SoundService
	return group
end

local function ensureInit()
	if initialized then
		return
	end
	initialized = true

	soundGroups.SFX = ensureGroup("SFX", 0.85)
	soundGroups.Music = ensureGroup("Music", 0.55)
	soundGroups.UI = ensureGroup("UI", 0.80)

	local existing2D = SoundService:FindFirstChild("LegendaryCatch_Sfx2D")
	if existing2D and existing2D:IsA("Folder") then
		folder2D = existing2D
	else
		local f = Instance.new("Folder")
		f.Name = "LegendaryCatch_Sfx2D"
		f.Parent = SoundService
		folder2D = f
	end

	local existing3D = Workspace:FindFirstChild("_LegendaryCatch_Sfx3D")
	if existing3D and existing3D:IsA("Folder") then
		folder3D = existing3D
	else
		local f = Instance.new("Folder")
		f.Name = "_LegendaryCatch_Sfx3D"
		f.Parent = Workspace
		folder3D = f
	end
end

local function acquire2DSound(): Sound
	local s = table.remove(pool2D)
	if s and s.Parent then
		return s
	end
	local created = Instance.new("Sound")
	created.Name = "Pooled2DSound"
	created.Parent = folder2D
	return created
end

local function release2DSound(s: Sound)
	if not s.Parent then
		return
	end
	s:Stop()
	s.Looped = false
	s.SoundId = ""
	if #pool2D < MAX_2D_POOL then
		s.Parent = folder2D
		table.insert(pool2D, s)
	else
		s:Destroy()
	end
end

local function acquire3DEmitter(): { part: Part, sound: Sound }
	local entry = table.remove(pool3D)
	if entry and entry.part.Parent and entry.sound.Parent then
		return entry
	end
	local p = Instance.new("Part")
	p.Name = "Pooled3DSoundEmitter"
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)

	local s = Instance.new("Sound")
	s.Name = "EmitterSound"
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = 95
	s.Parent = p

	p.Parent = folder3D
	return { part = p, sound = s }
end

local function release3DEmitter(entry: { part: Part, sound: Sound })
	if not entry.part.Parent then
		return
	end
	entry.sound:Stop()
	entry.sound.Looped = false
	entry.sound.SoundId = ""
	if #pool3D < MAX_3D_POOL then
		table.insert(pool3D, entry)
	else
		entry.part:Destroy()
	end
end

local function checkCooldown(name: string, cooldown: number): boolean
	if cooldown <= 0 then
		return true
	end
	local now = os.clock()
	local prev = lastPlayedAt[name]
	if prev and (now - prev) < cooldown then
		return false
	end
	lastPlayedAt[name] = now
	return true
end

local function computeSpeed(basePitch: number, jitter: number): number
	if jitter <= 0 then
		return math.clamp(basePitch, 0.25, 3.0)
	end
	local delta = rng:NextNumber(-jitter, jitter)
	return math.clamp(basePitch * (1 + delta), 0.25, 3.0)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function SfxKit.init()
	ensureInit()
end

function SfxKit.registerId(name: string, assetId: string)
	SOUND_IDS[name] = assetId
end

function SfxKit.hasValidId(name: string): boolean
	return resolveSoundAsset(name) ~= nil
end

function SfxKit.setCategoryVolume(category: SoundCategory, volume: number)
	ensureInit()
	local group = soundGroups[category]
	if group then
		group.Volume = math.clamp(volume, 0, 2)
	end
end

function SfxKit.getCategoryVolume(category: SoundCategory): number
	ensureInit()
	local group = soundGroups[category]
	return if group then group.Volume else 1
end

-- Play a 2D (or custom-parented) sound safely with cooldown & pitch jitter
function SfxKit.play(name: string, options: PlayOptions?): Sound?
	ensureInit()
	local asset = resolveSoundAsset(name)
	if not asset then
		return nil
	end

	local meta = SOUND_META[name] or DEFAULT_META
	local opts = options or {} :: PlayOptions
	local cooldown = if opts.cooldown ~= nil then opts.cooldown else meta.cooldown
	if not checkCooldown(name, cooldown) then
		return nil
	end

	local category: SoundCategory = opts.category or meta.category
	local sound = acquire2DSound()
	sound.SoundId = asset
	sound.SoundGroup = soundGroups[category] or soundGroups.SFX
	sound.Volume = if opts.volume ~= nil then opts.volume else meta.volume
	local basePitch = opts.pitch or 1.0
	local jitter = if opts.pitchJitter ~= nil then opts.pitchJitter else meta.pitchJitter
	sound.PlaybackSpeed = computeSpeed(basePitch, jitter)
	sound.Looped = opts.looped == true
	if opts.parent then
		sound.Parent = opts.parent
	else
		sound.Parent = folder2D
	end

	sound:Play()

	if not sound.Looped then
		local conn: RBXScriptConnection? = nil
		local released = false
		local function done()
			if released then
				return
			end
			released = true
			if conn then
				conn:Disconnect()
				conn = nil
			end
			release2DSound(sound)
		end
		conn = sound.Ended:Connect(done)
		-- Safety timeout in case asset fails to load or never fires Ended
		task.delay(12, done)
	end

	return sound
end

-- Play a 3D positional sound at a world Vector3 with RollOffMaxDistance
function SfxKit.playAt(name: string, position: Vector3, options: PlayOptions?): Sound?
	ensureInit()
	local asset = resolveSoundAsset(name)
	if not asset then
		return nil
	end

	local meta = SOUND_META[name] or DEFAULT_META
	local opts = options or {} :: PlayOptions
	local cooldown = if opts.cooldown ~= nil then opts.cooldown else meta.cooldown
	if not checkCooldown(name, cooldown) then
		return nil
	end

	local entry = acquire3DEmitter()
	entry.part.CFrame = CFrame.new(position)

	local sound = entry.sound
	local category: SoundCategory = opts.category or meta.category
	sound.SoundId = asset
	sound.SoundGroup = soundGroups[category] or soundGroups.SFX
	sound.Volume = if opts.volume ~= nil then opts.volume else meta.volume
	sound.RollOffMinDistance = opts.rollOffMin or 10
	sound.RollOffMaxDistance = opts.rollOffMax or meta.rollOffMax
	local basePitch = opts.pitch or 1.0
	local jitter = if opts.pitchJitter ~= nil then opts.pitchJitter else meta.pitchJitter
	sound.PlaybackSpeed = computeSpeed(basePitch, jitter)
	sound.Looped = opts.looped == true

	sound:Play()

	if not sound.Looped then
		local conn: RBXScriptConnection? = nil
		local released = false
		local function done()
			if released then
				return
			end
			released = true
			if conn then
				conn:Disconnect()
				conn = nil
			end
			release3DEmitter(entry)
		end
		conn = sound.Ended:Connect(done)
		task.delay(12, done)
	end

	return sound
end

-- Stop a looped sound returned by SfxKit.play / SfxKit.playAt safely
function SfxKit.stopSound(sound: Sound?)
	if not sound then
		return
	end
	sound:Stop()
	sound.Looped = false
	if sound.Parent == folder2D then
		release2DSound(sound)
	elseif sound.Parent and sound.Parent:IsA("Part") and sound.Parent.Parent == folder3D then
		release3DEmitter({ part = sound.Parent, sound = sound })
	end
end

local function cancelMusicTweens()
	for _, tw in ipairs(activeMusicTweens) do
		tw:Cancel()
	end
	table.clear(activeMusicTweens)
end

-- Smoothly crossfade ambient music between regions (hub / pier / training / aquarium / expedition / event)
function SfxKit.setRegionMusic(region: MusicRegion, fadeTime: number?)
	ensureInit()
	if activeMusicRegion == region then
		return
	end
	activeMusicRegion = region

	local duration = math.max(0.1, fadeTime or 1.4)
	cancelMusicTweens()

	local oldSound = activeMusicSound
	activeMusicSound = nil

	if oldSound and oldSound.Parent then
		local fadeOut = TweenService:Create(
			oldSound,
			TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{
				Volume = 0,
			}
		)
		table.insert(activeMusicTweens, fadeOut)
		fadeOut.Completed:Connect(function()
			oldSound:Stop()
			oldSound:Destroy()
		end)
		fadeOut:Play()
	end

	local soundName = REGION_TO_SOUND[region]
	if not soundName then
		return
	end
	local asset = resolveSoundAsset(soundName)
	if not asset then
		-- Placeholder ID: stay silent cleanly without errors
		return
	end

	local newSound = Instance.new("Sound")
	newSound.Name = "RegionMusic_" .. region
	newSound.SoundId = asset
	newSound.SoundGroup = soundGroups.Music
	newSound.Looped = true
	newSound.Volume = 0
	newSound.Parent = folder2D
	newSound:Play()

	activeMusicSound = newSound
	local fadeIn = TweenService:Create(
		newSound,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{
			Volume = musicBaseVolume,
		}
	)
	table.insert(activeMusicTweens, fadeIn)
	fadeIn:Play()
end

function SfxKit.stopMusic(fadeTime: number?)
	ensureInit()
	activeMusicRegion = nil
	cancelMusicTweens()
	local oldSound = activeMusicSound
	activeMusicSound = nil
	if not oldSound or not oldSound.Parent then
		return
	end
	local duration = math.max(0.05, fadeTime or 0.8)
	local fadeOut = TweenService:Create(
		oldSound,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			Volume = 0,
		}
	)
	fadeOut.Completed:Connect(function()
		oldSound:Stop()
		oldSound:Destroy()
	end)
	fadeOut:Play()
end

function SfxKit.destroy()
	SfxKit.stopMusic(0.05)
	for _, s in ipairs(pool2D) do
		s:Destroy()
	end
	table.clear(pool2D)
	for _, entry in ipairs(pool3D) do
		entry.part:Destroy()
	end
	table.clear(pool3D)
	if folder2D then
		folder2D:Destroy()
		folder2D = nil
	end
	if folder3D then
		folder3D:Destroy()
		folder3D = nil
	end
	table.clear(lastPlayedAt)
	initialized = false
end

return SfxKit
