#pragma once

// Include the modloader header, which allows us to tell the modloader which mod this is, and the version etc.
#include "custom-types/shared/macros.hpp"

// Define these functions here so that we can easily read configuration and log information from other files


using namespace UnityEngine;

/// @brief Stores the ID and version of our mod, and is sent to the modloader upon startup
modloader::ModInfo modInfo{MOD_ID, VERSION, 0};

/// @brief A logger, useful for printing debug messages
/// @return
static constexpr auto Logger = Paper::ConstLoggerContext(MOD_ID);

#define MOD_EXPORT __attribute__((visibility("default")))
#ifdef __cplusplus
#define MOD_EXPORT_FUNC extern "C" MOD_EXPORT
#else
#define MOD_EXPORT_FUNC MOD_EXPORT
#endif
