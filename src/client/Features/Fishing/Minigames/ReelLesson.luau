--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Theme = require(ReplicatedStorage.Shared.UiTheme)
local Text = require(ReplicatedStorage.Shared.StringsUi).minigames
local Ui = require(script.Parent.Parent:WaitForChild("Ui"))

local Lesson = {}
export type View = {
	active: () -> boolean,
	press: (Vector2?) -> (),
	update: (number) -> (),
	stop: () -> (),
}
local shownFor: Model? = nil

function Lesson.show(): View?
	local player = Players.LocalPlayer
	if shownFor == player.Character or player:GetAttribute("ReelTutorialHidden") == true then
		return nil
	end
	shownFor = player.Character
	local gui = Instance.new("ScreenGui")
	gui.Name = "ReelLesson"
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 9
	gui.ResetOnSpawn = false
	local card = Ui.frame(
		gui,
		"Lesson",
		UDim2.new(0.9, 0, 0, 222),
		UDim2.fromScale(0.5, 0.52),
		Theme.crystal
	)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	Theme.surface(card, Theme.crystal, 24)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(470, 222)
	limit.Parent = card
	Ui.label(
		card,
		"Title",
		UDim2.fromScale(0.9, 0.15),
		UDim2.fromScale(0.05, 0.04),
		Text.reelTitle,
		Theme.sand
	)
	local body = Ui.label(
		card,
		"Instructions",
		UDim2.fromScale(0.68, 0.49),
		UDim2.fromScale(0.04, 0.22),
		Text.reelLesson,
		Theme.sand
	)
	body.TextWrapped = true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MaxTextSize = 19
	cap.Parent = body
	local rail = Ui.frame(
		card,
		"DemoTrack",
		UDim2.fromScale(0.1, 0.46),
		UDim2.fromScale(0.79, 0.23),
		Theme.track
	)
	Ui.corner(rail, 0.4)
	local zone =
		Ui.frame(rail, "DemoZone", UDim2.fromScale(1, 0.32), UDim2.fromScale(0, 0.34), Theme.gold)
	Ui.corner(zone, 0.35)

	local function button(name: string, text: string, x: number, accent: Color3): TextButton
		local target = Instance.new("TextButton")
		target.Name = name
		target.Size = UDim2.new(0.44, 0, 0, 44)
		target.Position = UDim2.new(x, 0, 1, -56)
		target.Text = text
		target.Font = Theme.font
		target.TextSize = 14
		target.TextColor3 = Theme.sand
		target.TextStrokeColor3 = Theme.ink
		target.TextStrokeTransparency = 0.1
		Theme.surface(target, accent, 18)
		target.Parent = card
		return target
	end
	local ready = button("Ready", Text.reelReady, 0.04, Theme.gold)
	local hide = button("HideNextTime", Text.reelHide, 0.52, Theme.rose)
	gui.Parent = player.PlayerGui
	local elapsed = 0
	local active = true
	local function close()
		if not active then
			return
		end
		active = false
		gui:Destroy()
	end
	local function contains(target: GuiObject, point: Vector2): boolean
		local localPoint = point - target.AbsolutePosition
		return localPoint.X >= 0
			and localPoint.Y >= 0
			and localPoint.X <= target.AbsoluteSize.X
			and localPoint.Y <= target.AbsoluteSize.Y
	end
	return {
		active = function(): boolean
			return active
		end,
		press = function(point: Vector2?)
			if not active then
				return
			end
			if point and contains(hide, point) then
				local hidden = player:GetAttribute("ReelTutorialHidden") ~= true
				player:SetAttribute("ReelTutorialHidden", hidden)
				hide.Text = (if hidden then "✓ " else "") .. Text.reelHide
			elseif not point or contains(ready, point) then
				close()
			end
		end,
		update = function(dt: number)
			if not active then
				return
			end
			elapsed += dt
			ready.Text = string.format(Text.reelStartIn, math.max(0, math.ceil(8 - elapsed)))
			if player:GetAttribute("ReduceEffects") ~= true then
				zone.Position = UDim2.fromScale(0, 0.34 + math.sin(elapsed * 3) * 0.28)
			else
				zone.Position = UDim2.fromScale(0, 0.34)
			end
			if elapsed >= 8 then
				close()
			end
		end,
		stop = close,
	}
end

return Lesson
