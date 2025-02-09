#pragma once

#include "config-utils/shared/config-utils.hpp"
#include <string>

DECLARE_CONFIG(Config) {
    CONFIG_VALUE(IsStock, bool, "Mod Enabled", true);
    CONFIG_VALUE(MaxSpeed, float, "Max Scroll Speed", 600);
    CONFIG_VALUE(Accel, float, "Scroll Acceleration", 2.5);
    CONFIG_VALUE(IsLinear, bool, "Scrolling is Linear", false);
};
