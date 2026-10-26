
local primary = "rgb(0000aa)"
local surface = "rgb(aaaaaa)"
local on_surface = "rgb(000000)"
local secondary = "rgb(0000aa)"
local on_secondary = "rgb(ffffff)"
local error = "rgb(aa0000)"
local on_error = "rgb(ffffff)"

local function apply_theme()
    hl.config({
        general = {
            col = {
                active_border = primary,
                inactive_border = surface,
            },
        },
        group = {
            col = {
                border_active = secondary,
                border_inactive = surface,
                border_locked_active = error,
                border_locked_inactive = surface,
            },

            groupbar = {
                col = {
                    active = secondary,
                    inactive = surface,
                    locked_active = error,
                    locked_inactive = surface,
                },
                text_color = on_secondary,
                text_color_inactive = on_surface,
                text_color_locked_active = on_error,
                text_color_locked_inactive = on_surface,
            },
        },
    })
    hl.config({
        general = {
            gaps_in  = {top = 14, right = 16, bottom = 14, left = 16},
            gaps_out = {top = 18, right = 32, bottom = 28, left = 16},
        },
        decoration = {
            shadow = {
                enabled = true,
                range   = 0,
                sharp   = true,
                offset  = {16, 14},
                color   = 0xff000000,
            },
        },
        plugin = {
            hyprbars = {
                bar_text_align = "center",
            },
        },
    })
end

return {
    colors = {
        primary = primary,
        surface = surface,
        on_surface = on_surface,
        secondary = secondary,
        on_secondary = on_secondary,
        error = error,
        on_error = on_error,
    },
    apply_theme = apply_theme
}
