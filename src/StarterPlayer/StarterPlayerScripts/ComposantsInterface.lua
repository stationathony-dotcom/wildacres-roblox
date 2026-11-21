local Composants = {}

local ETATS = {
	disponible = { "✓", Color3.fromRGB(62, 113, 61) },
	selectionne = { "◆", Color3.fromRGB(113, 78, 41) },
	verrouille = { "⊘", Color3.fromRGB(76, 69, 62) },
}

Composants.PICTOGRAMMES = table.freeze({ fermer = "×", avertissement = "!" })

-- Certains pictogrammes du catalogue et des messages serveur manquent à la police Roblox.
local SECOURS = {
	["🪓"] = "⚒️", ["🪚"] = "🛠️", ["🪄"] = "✨", ["🪖"] = "🛡️",
	["🪵"] = "🌲", ["🪨"] = "⛰️", ["🪙"] = "💰", ["🪣"] = "💧",
	["🪑"] = "🏠", ["🛖"] = "🏠", ["🪟"] = "🔲", ["🪔"] = "🕯️",
	["🪕"] = "🎵", ["🪁"] = "🎏", ["🪿"] = "🦆", ["🧌"] = "👹",
}

function Composants.texteCompatible(texte: string): string
	local astral = "[\240-\244][\128-\191][\128-\191][\128-\191]"
	local normalise = texte:gsub("(" .. astral .. ")️", function(glyphe)
		return SECOURS[glyphe] or (glyphe .. "️")
	end)
	return (normalise:gsub(astral, SECOURS))
end

function Composants.creer(class: string, props, children)
	local element = Instance.new(class)
	for key, value in props or {} do
		if key == "Text" and class ~= "TextBox" then
			element.Text = Composants.texteCompatible(value)
		elseif key ~= "Parent" then
			(element :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = element
	end
	if props and props.Parent then
		element.Parent = props.Parent
	end
	return element
end

function Composants.titre(props)
	props.BackgroundTransparency = 1
	props.TextXAlignment = Enum.TextXAlignment.Left
	props.TextTruncate = Enum.TextTruncate.AtEnd
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextSize = props.TextSize or 22
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(239, 199, 116)
	return Composants.creer("TextLabel", props)
end

function Composants.bouton(props, action, children)
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(250, 241, 222)
	props.AutoButtonColor = true
	local bouton = Composants.creer("TextButton", props, children)
	if action then
		bouton.Activated:Connect(action)
	end
	return bouton
end

function Composants.etatBouton(bouton, texte, etat, couleurNeutre)
	local style = ETATS[etat]
	bouton.Text = Composants.texteCompatible(style and style[1] .. " " .. texte or texte)
	bouton.BackgroundColor3 = style and style[2] or couleurNeutre
	bouton.Interactable = etat ~= "verrouille"
end

function Composants.quantite(n: number, total: number?)
	if total then
		return string.format("%d / %d", n, total)
	end
	return "×" .. n
end

function Composants.avertissement(texte: string)
	return Composants.PICTOGRAMMES.avertissement .. "  " .. Composants.texteCompatible(texte)
end

return Composants
