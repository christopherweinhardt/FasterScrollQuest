#pragma once

#include "scotland2/shared/loader.hpp"

#if __has_include("git-info.h")
#include "git-info.h"
#endif

#ifdef GIT_VERSION
// Use the git info if available
// -----------------------------

/// @brief Stores the ID and version of our mod, and is sent to the modloader upon startup
inline modloader::ModInfo const modInfo{MOD_ID, GIT_VERSION, 0};
#else
// Fallback to using the version defined by the mod
// ------------------------------------------------

/// @brief Stores the ID and version of our mod, and is sent to the modloader upon startup
inline modloader::ModInfo const modInfo{MOD_ID, VERSION, 0};
#endif
