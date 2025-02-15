#pragma once

#include <string>

#include "config-utils/shared/config-utils.hpp"

DECLARE_CONFIG(Config) {
    CONFIG_VALUE(IsStock, bool, "Mod Enabled", true, "Toggles whether the mod is active or not.");
    CONFIG_VALUE(MaxSpeed, float, "Max Scroll Speed", 600, "Changes the speed of scrolling with the joystick. Default: 600");
    CONFIG_VALUE(Accel, float, "Scroll Acceleration", 2.5, "Changes the acceleration speed of scrolling with the joystick. Default: 2.5");
    CONFIG_VALUE(IsLinear, bool, "Scrolling is Linear", false, "Toggles whether you want to use acceleration or not.");
};

inline void ConfigViewDidLoad(HMUI::ViewController* self, bool firstActivation, bool addedToHierarchy, bool screenSystemEnabling) {
    if (firstActivation) {
        auto container = BSML::Lite::CreateScrollableSettingsContainer(self->get_transform());
        auto parent = container->get_transform();

        AddConfigValueToggle(parent, getConfig().IsStock);
        AddConfigValueIncrementFloat(parent, getConfig().MaxSpeed, 0, 10, 30, 1000);
        AddConfigValueIncrementFloat(parent, getConfig().Accel, 1, 0.1, 0.5, 5);
        AddConfigValueToggle(parent, getConfig().IsLinear);
    }
}
