return function(parent, origin)
    local model = Instance.new("Model")
    model.Name = "Mammouth_sol"

    local sombre = Color3.fromRGB(56, 37, 39)
    local brun = Color3.fromRGB(94, 62, 55)
    local fauve = Color3.fromRGB(132, 90, 73)
    local os = Color3.fromRGB(190, 164, 128)
    local ivoire = Color3.fromRGB(240, 237, 218)
    local givre = Color3.fromRGB(143, 191, 226)
    local cyan = Color3.fromRGB(54, 225, 255)
    local neon = Enum.Material.Neon
    local rad = math.rad
    local n = 0

    local function bloc(nom, x, y, z, largeur, hauteur, profondeur, couleur, repere, matiere)
        local part = Instance.new("Part")
        part.Name = nom
        part.Size = Vector3.new(largeur, hauteur, profondeur)
        part.CFrame = origin * (repere or CFrame.new()) * CFrame.new(x, y, z)
        part.Color = couleur
        part.Material = matiere or Enum.Material.SmoothPlastic
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        part.Anchored = true
        part.CanCollide = false
        part.Parent = model
        n = n + 1
        return part
    end

    local function axe(depart, arrivee)
        local delta = arrivee - depart
        return CFrame.lookAt(depart:Lerp(arrivee, 0.5), arrivee), delta.Magnitude
    end

    local base = bloc("Base", 0, 0.1, 0, 1, 0.2, 1, sombre)
    base.Transparency = 1
    base.CastShadow = false
    base.PivotOffset = CFrame.new(0, -0.1, 0)
    model.PrimaryPart = base

    -- La bosse culmine au garrot. Les gradins se resserrent vers la croupe.
    bloc("Ventre", 0, 8.75, 0.96, 8.6, 5.8, 14.6, sombre)
    bloc("Cage thoracique", 0, 10.8, 0, 10.6, 4.4, 14.6, brun)
    bloc("Épaules", 0, 12.1, -3.5, 11.3, 5.8, 7.9, brun)
    bloc("Garrot inférieur", 0, 14.7, -3.2, 9.8, 3.6, 8, brun)
    bloc("Garrot supérieur", 0, 16.0, -3.0, 7.7, 3, 6.5, fauve)
    bloc("Dos", 0, 15.05, 1.70, 8.8, 2.9, 6.2, fauve)
    bloc("Reins", 0, 12.0, 4.1, 10.4, 4.3, 7.6, brun)
    bloc("Croupe haute", 0, 13.9, 5.5, 8.8, 2.6, 5.0, brun)
    bloc("Croupe basse", 0, 11.75, 8.13, 8.4, 3.9, 2.5, brun)
    bloc("Arrière-train", 0, 9.3, 8.05, 7.8, 4.8, 2.85, sombre)

    local cotes = {-1, 1}
    local pattes = {
        {-1, -5.55, 1.00}, {1, -5.12, 1.03},
        {-1, 6.10, 0.91}, {1, 6.66, 0.94},
    }
    for i, patte in ipairs(pattes) do
        local cote, z, taille = patte[1], patte[2], patte[3]
        local x = cote * (3.87 + 0.23 * taille)
        bloc("Pied", x, 0.65, z, 3.24 * taille, 1.30, 3.52 * taille, sombre)
        bloc("Paturon", x - cote * 0.12, 1.61, z + 0.12, 2.94 * taille, 1.38, 3.12 * taille, brun)
        bloc("Jambe", x - cote * 0.26, 3.22, z + 0.18, 2.73 * taille, 2.45, 2.98 * taille, brun)
        bloc("Haut de patte", x - cote * 0.37, 5.86, z + 0.23, 3.56 * taille, 4.56, 4.15 * taille, sombre)
        bloc("Toison du genou", x + cote * 0.79, 4.66, z - 0.71, 1.58 * taille, 2.51, 2.36 * taille, brun)
        bloc("Pointe de toison", x + cote * 0.96, 3.55, z - 0.82, 0.91 * taille, 1.21, 1.18 * taille, fauve)

        for orteil = -1, 1 do
            local central = orteil == 0
            bloc("Ongle", x + 0.88 * taille * orteil, 0.42, z - (central and 1.71 or 1.59) * taille,
                (central and 0.78 or 0.67) * taille, 0.84, 0.63 * taille, central and ivoire or os)
        end

        bloc("Corniche gelée du pied", x, 2.44, z - 1.24 * taille, 2.63 * taille, 0.54, 0.68 * taille, givre)
        bloc("Retombée de givre du pied", x + cote * 0.85, 2.10, z - 1.46 * taille,
            0.68 * taille, 0.72, 0.42 * taille, givre)
        bloc("Neige sur le paturon", x - cote * 0.43, 2.69, z - 1.47 * taille,
            1.14 * taille, 0.34, 0.38 * taille, ivoire)
        if i <= 2 then
            bloc("Givre du côté du pied", x + cote * 1.27 * taille, 2.28, z - 0.70 * taille,
                0.46, 0.68, 1.34 * taille, givre)
        end
    end

    -- Grandes mèches de couverture. Les pointes décalées cassent la ligne du ventre.
    -- Z, écart à l'axe, haut de mèche, longueur, profondeur.
    local flancs = {
        {-6.10, 4.76, 14.38, 5.38, 2.17}, {-4.29, 5.58, 14.00, 6.46, 2.35},
        {-2.44, 5.61, 13.96, 5.66, 2.45}, {-0.52, 5.47, 13.3, 5.42, 2.51},
        {1.50, 5.15, 12.95, 5.12, 2.45}, {3.51, 5.15, 12.87, 4.78, 2.50},
        {5.53, 5.14, 12.61, 5.40, 2.46}, {7.50, 4.69, 12.05, 4.98, 2.37},
    }
    for _, cote in ipairs(cotes) do
        for i, meche in ipairs(flancs) do
            local z, x, haut, longueur, epaisseur = table.unpack(meche)
            local decalage = (i % 3 - 1) * 0.31 * cote
            local repere = CFrame.new(cote * x, haut, z + decalage)
                * CFrame.Angles(rad(-7 + 2 * ((i + cote) % 4)), 0, rad(cote * (i % 3 - 1) * 3))
            bloc("Mèche de flanc", 0, -longueur / 2, 0,
                1.65, longueur, epaisseur, i % 3 == 0 and sombre or brun, repere)
            if i % 2 == 1 then
                bloc("Relief de la mèche", cote * 0.73, -longueur * 0.37, -0.30,
                    0.56, longueur * 0.53, epaisseur * 0.62, i % 3 == 2 and brun or fauve, repere)
            end
            bloc("Pointe de la mèche", cote * 0.28, -longueur + 0.02, 0.48,
                1.14, 1.26 + (i % 3) * 0.23, epaisseur * 0.46, i % 3 == 0 and brun or sombre, repere)
        end
        bloc("Mèche arrière", cote * 2.26, 10.1, 9.35, 2.08, 4.10, 0.93, brun)
        bloc("Pointe arrière", cote * 2.46, 8.12, 9.49, 1.12, 1.83, 0.71, sombre)
    end

    local queue = CFrame.new(0, 9.0, 9.29) * CFrame.Angles(rad(-19), 0, rad(12))
    bloc("Racine de la queue", 0, 0.24, 0, 1.54, 1.78, 1.16, brun, queue)
    bloc("Queue", 0, -0.98, 0.13, 1.07, 1.55, 1.04, brun, queue)
    bloc("Touffe de la queue", 0, -1.89, 0.18, 1.53, 1.20, 1.19, sombre, queue)

    -- La neige forme un manteau continu au sommet, puis se déchire sur les flancs.
    -- Z, altitude du manteau, largeur, profondeur, écart de corniche, chute du bord.
    local manteau = {
        {-5.60, 17.29, 7.01, 2.56, 4.35, 3.43}, {-3.24, 17.66, 8.06, 2.61, 4.73, 3.55},
        {-0.78, 17.51, 7.82, 2.59, 4.52, 3.1}, {1.62, 16.76, 7.66, 2.68, 4.48, 3.3},
        {3.99, 16.58, 7.62, 2.43, 4.42, 3.57}, {6.10, 15.30, 7.22, 2.48, 4.32, 3.18},
        {7.98, 14.52, 6.61, 2.24, 3.99, 3.39},
    }
    for i, rangee in ipairs(manteau) do
        local z, y, largeur, profondeur, x, chute = table.unpack(rangee)
        local decalage = (i % 3 - 1) * 0.28
        bloc("Plaque de givre dorsal", decalage, y, z, largeur, 1.06, profondeur, givre)
        bloc("Neige tassée", decalage * 3, y + 0.58, z - 0.10,
            largeur * 0.76, 0.32, profondeur * 0.69, ivoire)
        for _, cote in ipairs(cotes) do
            local pli = x + cote * decalage * 0.33
            local zPli = z + cote * decalage
            local retombee = chute + cote * decalage
            bloc("Corniche latérale", cote * pli, y - 0.73, zPli, 2.36, 1.19, profondeur * 0.92, givre)
            if (2 * i + cote) % 4 == 1 then
                bloc("Ourlet de neige", cote * (pli + 0.27), y - 0.13, zPli - profondeur * 0.12,
                    1.43, 0.3, profondeur * 0.61, ivoire)
            end
            bloc("Langue de glace", cote * (pli + 0.57), y - retombee * 0.51, zPli - 0.24,
                1.07, retombee * 0.66, profondeur * 0.61, givre)
            bloc("Pointe de glace", cote * (pli + 0.69), y - retombee * 0.87, zPli - 0.49,
                0.62, retombee * 0.41, profondeur * 0.28, i % 3 == 0 and ivoire or givre)
        end
    end
    bloc("Givre de croupe", 0, 13.36, 9.25, 6.60, 1.44, 0.93, givre)
    bloc("Frange de croupe", -0.86, 12.43, 9.51, 1.44, 1.67, 0.73, givre)
    bloc("Frange claire de croupe", 1.2, 12.94, 9.61, 1.1, 1.06, 0.46, ivoire)

    -- La crête se brise par paliers. Un filon oblique affleure sur la face des prismes.
    local function cristal(x, y, z, largeur, hauteur, profondeur, inclinaison, lacet, roulis)
        local repere = CFrame.new(x, y, z) * CFrame.Angles(rad(inclinaison), rad(lacet), rad(roulis))
        if hauteur >= 2.18 then
            bloc("Pied du cristal", 0, 0.18, 0, largeur * 1.28, 0.57, profondeur * 1.2, givre, repere)
        end
        bloc("Prisme de glace", 0, hauteur * 0.40, 0,
            largeur, hauteur * 0.82, profondeur, givre, repere)
        local arete = repere * CFrame.new(-largeur * 0.08, hauteur * 0.79, profondeur * 0.07)
            * CFrame.Angles(rad(13), 0, rad(roulis < 0 and -24 or 28))
        bloc("Prisme haut", 0, 0, 0, largeur * 0.72, hauteur * 0.47, profondeur * 0.84, givre, arete)
        bloc("Sommet du cristal", largeur * 0.09, hauteur * 0.15, -profondeur * 0.20,
            largeur * 0.32, hauteur * 0.28, profondeur * 0.48, ivoire, arete)
        local filon = repere * CFrame.new(largeur * 0.04, hauteur * 0.48, -profondeur * 0.5)
            * CFrame.Angles(0, 0, rad(roulis < 0 and 14 or -17))
        bloc("Filon cyan", 0, 0, 0, largeur * 0.31, hauteur * 0.62, 0.15, cyan, filon, neon)
        if hauteur >= 2.18 then
            local tranche = repere * CFrame.new(largeur * 0.5, hauteur * 0.38, -profondeur * 0.06)
                * CFrame.Angles(rad(16), 0, 0)
            bloc("Retour du filon", 0, 0, 0, 0.14, hauteur * 0.50, profondeur * 0.25, cyan, tranche, neon)
        end
    end

    cristal(-0.65, 17.55, -4.95, 1.57, 2.19, 1.43, 13, -19, 9)
    cristal(0.38, 17.95, -2.64, 2.19, 3.14, 1.67, 18, 17, -10)
    cristal(-0.72, 17.81, -0.20, 1.66, 2.38, 1.41, 22, -16, 12)
    cristal(0.30, 16.99, 2.16, 1.98, 2.81, 1.60, 20, 15, -10)
    cristal(-0.42, 16.89, 4.30, 1.42, 2.18, 1.30, 24, -11, 10)
    cristal(0.52, 15.55, 6.22, 1.36, 1.87, 1.13, 24, 18, -11)
    cristal(-0.11, 14.80, 8.06, 1.08, 1.34, 0.98, 24, -13, 8)
    cristal(-2.26, 17.71, -2.9, 1.16, 1.45, 1.02, 9, -15, 24)
    cristal(2.10, 17.02, 1.34, 1.14, 1.60, 0.94, 16, 22, -24)

    bloc("Crâne", 0, 12.25, -8.34, 7.18, 6.20, 5.42, brun)
    bloc("Front", 0, 13.94, -9.08, 6.10, 2.65, 4.13, fauve)
    bloc("Mâchoire", 0, 10.15, -9.43, 5.34, 3.05, 3.88, sombre)
    bloc("Bavoir", 0, 8.48, -7.98, 5.68, 3.88, 3.42, sombre)
    bloc("Pointe du bavoir", 0.18, 6.73, -8.16, 2.1, 2.18, 2.42, brun)
    bloc("Racine de la trompe", 0, 11.63, -11.28, 2.73, 1.46, 1.59, fauve)
    bloc("Nœud des sourcils", 0, 12.89, -11.22, 1.82, 1.10, 1.26, brun)

    for _, cote in ipairs(cotes) do
        local tempe = CFrame.new(cote * 2.49, 12.36, -11.07) * CFrame.Angles(0, rad(-27 * cote), 0)
        local regard = tempe * CFrame.Angles(0, 0, rad(15 * cote))
        bloc("Orbite", 0, 0, 0, 2.09, 1.21, 0.70, sombre, regard)
        bloc("Œil", 0, -0.07, -0.40, 1.43, 0.45, 0.21, cyan, regard, neon)
        bloc("Reflet de l’œil", -0.28 * cote, 0.03, -0.50, 0.63, 0.31, 0.13, cyan, regard, neon)
        bloc("Arcade", 0.05 * cote, 0.62, -0.13, 2.25, 0.68, 1.02, fauve, regard)
        bloc("Arcade extérieure", 0.83 * cote, 0.93, 0.19, 0.98, 0.62, 1.03, brun, regard)
        bloc("Mèche sous le givre du front", cote * 0.44, 1.69, 0.50, 0.89, 1.66, 0.51, brun, regard)

        local oreille = CFrame.new(cote * 3.96, 11.92, -8.78) * CFrame.Angles(rad(-9), rad(-29 * cote), rad(-10 * cote))
        bloc("Oreille laineuse", 0, 0, 0, 2.23, 3.35, 1.18, brun, oreille)
        bloc("Creux de l’oreille", 0.07 * cote, 0.02, -0.56, 1.42, 1.92, 0.32, sombre, oreille)
        bloc("Repli de l’oreille", 0.52 * cote, 0.33, -0.73, 0.53, 2.29, 0.41, fauve, oreille)
        bloc("Pointe de l’oreille", 0.21 * cote, -1.70, 0.13, 1.38, 0.96, 0.91, brun, oreille)

        bloc("Joue", cote * 3.07, 10.78, -10.59, 1.83, 2.16, 1.76, fauve)
        bloc("Favori", cote * 3.61, 9.64, -9.98, 1.54, 2.73, 1.75, brun)
        bloc("Pointe du favori", cote * 3.45, 8.37, -10.20, 0.94, 1.4, 1.02, sombre)
        bloc("Mèche de la tempe", cote * 3.31, 13.82, -9.76, 1.55, 1.92, 1.61, brun)
        bloc("Bord gelé de la tempe", cote * 3.28, 14.61, -9.83, 1.37, 1.48, 1.46, givre)
    end

    bloc("Coiffe de givre", 0, 15.37, -9.02, 6.17, 0.87, 3.59, givre)
    bloc("Neige du front", -0.20, 15.88, -8.78, 4.87, 0.39, 2.59, ivoire)
    bloc("Frange du front", -0.47, 15.32, -10.73, 3.72, 0.71, 1.07, givre)
    bloc("Coulée du front", -0.43, 14.77, -11.05, 1.03, 1.05, 0.66, givre)
    bloc("Bord clair de la coulée", -0.81, 15.20, -11.26, 0.52, 0.54, 0.31, ivoire)
    bloc("Éclat du front", 1.61, 15.39, -10.83, 0.90, 0.48, 0.81, ivoire)

    -- Trompe basse en S, avec des plis sur la face extérieure de la courbe.
    local trompe = {
        Vector3.new(0, 11.92, -11.25), Vector3.new(0, 10.67, -12.25),
        Vector3.new(-0.10, 9.10, -12.77), Vector3.new(-0.18, 7.50, -12.88),
        Vector3.new(-0.43, 6.00, -13.08), Vector3.new(-0.60, 4.78, -13.65),
        Vector3.new(-0.45, 4.19, -14.60), Vector3.new(-0.12, 4.30, -15.43),
        Vector3.new(0.30, 4.87, -16.06), Vector3.new(0.61, 5.59, -16.28),
    }
    for i = 1, #trompe - 1 do
        local repere, longueur = axe(trompe[i], trompe[i + 1])
        local largeur = 2.62 - (i - 1) * 0.175
        local hauteur = 1.99 - (i - 1) * 0.129
        bloc("Segment de trompe", 0, 0, 0, largeur, hauteur, longueur + 0.42, brun, repere)
        if i < 8 then
            bloc("Pli de trompe", 0, hauteur * 0.45, 0.03,
                largeur * 0.85, 0.36, longueur * 0.69, i % 3 == 0 and brun or fauve, repere)
        end
    end
    local bout = trompe[#trompe]
    local mufle = CFrame.lookAt(bout, bout + (bout - trompe[#trompe - 1]))
    bloc("Bout de la trompe", 0, 0, -0.13, 1.36, 1.07, 0.47, fauve, mufle)
    for _, cote in ipairs(cotes) do
        bloc("Narine", cote * 0.30, 0.025, -0.37, 0.31, 0.38, 0.08, sombre, mufle)
    end

    -- Les défenses plongent, s'écartent, puis reviennent vers l'axe en remontant.
    local courbe = {
        {2.49, 10.81, -10.82}, {3.12, 9.87, -12.07}, {3.78, 8.48, -13.12},
        {4.63, 7.27, -14.17}, {5.66, 6.86, -15.25}, {6.58, 7.22, -16.14},
        {6.98, 8.15, -16.98}, {6.90, 9.25, -17.68}, {6.43, 10.24, -18.02},
        {5.98, 10.85, -18.08},
    }
    local sections = {1.81, 1.67, 1.53, 1.39, 1.23, 1.06, 0.84, 0.59, 0.31}
    for _, cote in ipairs(cotes) do
        local points = {}
        for i, point in ipairs(courbe) do
            local progression = (i - 1) / (#courbe - 1)
            points[i] = Vector3.new(cote * (point[1] + cote * 0.13 * progression),
                point[2] + cote * 0.33 * progression, point[3] - cote * 0.28 * progression)
        end
        for i, section in ipairs(sections) do
            local repere, longueur = axe(points[i], points[i + 1])
            local teinte = i < 6 and os or (i == 6 and ivoire or givre)
            bloc("Segment de défense", 0, 0, 0, section, section * 0.90, longueur + 0.39, teinte, repere)
            if i < 6 then
                bloc("Ivoire de la défense", -cote * section * 0.07, section * 0.27, -0.01,
                    section * 0.90, section * 0.48, longueur + 0.14, ivoire, repere)
            elseif i > 6 and i < 9 then
                bloc("Arête givrée de la défense", -cote * section * 0.07, section * 0.30, -0.05,
                    section * 0.66, section * 0.36, longueur + 0.16, ivoire, repere)
            end
            if i == 6 then
                bloc("Givre en selle", 0.13 * cote, 0.34, 0.08, 1.20, 0.75, longueur * 0.92, givre, repere)
                bloc("Givre pendant", 0.59 * cote, -0.26, 0.12, 0.46, 0.85, 0.70, givre, repere)
            elseif i == 7 then
                local eclat = repere * CFrame.new(cote * 0.29, 0.17, 0.23) * CFrame.Angles(0, rad(20 * cote), 0)
                bloc("Éclat sur la défense", 0, 0, 0, 0.63, 0.71, 1.45, givre, eclat)
            end
        end
    end

    model:SetAttribute("Pieces", n)
    model.Parent = parent
    return model
end
