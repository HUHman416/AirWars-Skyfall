local flag_material_cache = {}

local function has_flag_material(model, model_path)
    if flag_material_cache[model_path] ~= nil then return flag_material_cache[model_path] end
    local found = false
    for _, material in ipairs(model:GetMaterials() or {}) do
        if material == "models/aw_model_materials/aw_flag_a" then
            found = true
            break
        end
    end
    flag_material_cache[model_path] = found
    return found
end

local function apply_ship_modulation(prop, ship, player_model)
    if player_model then
        render.SetColorModulation(1, 1, 1)
        return
    end

    local livery_id = ship.skyfall and ship.skyfall.livery or ship.livery or "brass"
    local color = Skyfall.GetLivery(livery_id).color
    local r = 0.68 + (color.r / 255) * 0.32
    local g = 0.68 + (color.g / 255) * 0.32
    local b = 0.68 + (color.b / 255) * 0.32

    if prop.health then
        local maximum = tonumber(prop.max_health or (prop.info and prop.info.health) or 100) or 100
        local health = math.Clamp((tonumber(prop.health) or 0) / math.max(1, maximum), 0, 1)
        g = g * (0.38 + health * 0.62)
        b = b * (0.38 + health * 0.62)
    end

    render.SetColorModulation(r, g, b)
end

local function draw(view, prop, ship, player)
    render.SetColorMaterial()
    local matrix = Matrix()
    matrix:Translate(ship.position)
    matrix:Rotate(ship.angles)
    matrix:Translate(prop.position - ship.center)
    matrix:Rotate(prop.angle)
    matrix = view * matrix

    local pos = matrix:GetTranslation()
    local local_ship_ref = world_ships[LocalPlayer():GetCurrentShip()]
    if aw_check_in_view(pos) and local_ship_ref and LocalPlayer():GetPos():Distance(pos) > 4000 then return end

    if ship.id == LocalPlayer():GetCurrentShip() then
        matrix = Matrix()
        matrix:Translate(prop.position - ship.center)
        matrix:Rotate(prop.angle)
    end

    local model = clientside_models[prop.model]
    if IsValid(model) then
        if prop.sequence then
            model:SetCycle(CurTime() % 1)
            model:SetSequence(prop.sequence)
        end
        model:EnableMatrix("RenderMultiply", matrix)
        model:SetupBones()
        if player then draw_hats(player, model) end

        apply_ship_modulation(prop, ship, player ~= nil)
        if has_flag_material(model, prop.model) then
            model:SetSubMaterial(2, "!AWFlagMaterial")
            aw_render_flag_texture(aw_flag_mat, ship.id)
        end
        model:DrawModel()
    else
        try_load_model(prop.model)
    end
    render.SetColorModulation(1, 1, 1)
end

function aw_draw_props(view)
    for _, ship in pairs(world_ships or {}) do
        for _, prop in pairs(ship.parts or {}) do
            draw(view, prop, ship)
            for _, subpart in pairs(prop.subparts or {}) do
                local subpart_renderer = {
                    model = subpart.model,
                    position = prop.position + subpart.offset,
                    angle = subpart.angle
                }
                draw(view, subpart_renderer, ship)
            end
        end

        for _, crew_member in pairs(get_crew(ship)) do
            if not IsValid(crew_member) or crew_member:GetCurrentShip() == LocalPlayer():GetCurrentShip() or crew_member:IsSpectator() then continue end
            local prop = {
                model = crew_member:GetModel(),
                position = crew_member:GetPos() + ship.center - global_config.world_center,
                angle = Angle(0, crew_member:EyeAngles().y),
                sequence = crew_member:GetSequenceName(crew_member:GetSequence())
            }
            draw(view, prop, ship, crew_member)
        end
    end
end
