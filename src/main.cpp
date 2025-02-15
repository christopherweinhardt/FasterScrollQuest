#include "main.hpp"

#include "autohooks/shared/hooks.hpp"
#include "beatsaber-hook/shared/utils/il2cpp-functions.hpp"
#include "config.hpp"
#include "custom-types/shared/macros.hpp"
#include "custom-types/shared/register.hpp"
#include "custom-types/shared/types.hpp"
#include "logger.hpp"
#include "modInfo.hpp"
#include "scotland2/shared/modloader.h"

// BSML
#include "bsml/shared/BSML.hpp"
using namespace BSML;

// GlobalNamespace
#include "GlobalNamespace/LevelCollectionTableView.hpp"
using namespace GlobalNamespace;

// HMUI
#include "HMUI/CurvedCanvasSettings.hpp"
#include "HMUI/CurvedTextMeshPro.hpp"
#include "HMUI/ScrollView.hpp"
#include "HMUI/TableView.hpp"
using namespace HMUI;

// UnityEngine
#include "UnityEngine/Canvas.hpp"
#include "UnityEngine/CanvasRenderer.hpp"
#include "UnityEngine/Mathf.hpp"
#include "UnityEngine/Time.hpp"
#include "UnityEngine/UI/CanvasScaler.hpp"
using namespace UnityEngine;

// Standard Library
#include <string>
using namespace std;

/// @brief Called at the early stages of game loading
/// @param info The mod info.  Update this with your mod's info.
/// @return
MOD_EXPORT_FUNC void setup(CModInfo& info) {
    // Convert the mod info to a C struct and set that as the modloader info.
    info = modInfo.to_c();

    getConfig().Init(modInfo);

    Logger.info("Completed setup!");
}

/// @brief Called early on in the game loading
/// @return
MOD_EXPORT_FUNC void load() {
    // Initialize il2cpp functions
    il2cpp_functions::Init();
    BSML::Init();
    BSML::Register::RegisterSettingsMenu("Faster Scroll", ConfigViewDidLoad, false);
    custom_types::Register::AutoRegister();

    // Get the number of early hooks that will be installed.
    auto earlyHookCount = EARLY_HOOK_COUNT;

    // install early hooks
    if (earlyHookCount > 0) {
        Logger.info("Installing {} early hook{}", earlyHookCount, earlyHookCount == 0 || earlyHookCount > 1 ? "s" : "");
        INSTALL_EARLY_HOOKS();
        Logger.info("Finished installing early hook{}", earlyHookCount == 0 || earlyHookCount > 1 ? "s" : "");
    }
}

/// @brief Called later on in the game loading - a good time to install function hooks
/// @return
MOD_EXPORT_FUNC void late_load() {
    // Get the number of late hooks that will be installed.
    auto lateHookCount = LATE_HOOK_COUNT;

    // Install late hooks
    if (lateHookCount > 0) {
        Logger.info("Installing {} late hook{}", lateHookCount, lateHookCount > 1 ? "s" : "");
        INSTALL_LATE_HOOKS();
        Logger.info("Finished installing late hook{}", lateHookCount == 0 || lateHookCount > 1 ? "s" : "");
    }
}

float m_fStockScrollSpeed;
float m_fInertia;
float m_fCustomSpeed;  // stock value : 60.0f
float m_fScrollTimer;

#define isLinear (getConfig().IsLinear.GetValue())
#define isntStock (getConfig().IsStock.GetValue())
#define accel (getConfig().Accel.GetValue())
#define maxSpeed (getConfig().MaxSpeed.GetValue())

float m_fVanillaStockRumbleStrength;  // stock value : 1.0f (will be set ONCE at launch)
float m_fRumbleStrength;
std::string str = "LevelsTableView";

void SetStockScrollSpeed(ScrollView* sv) {
    m_fStockScrollSpeed = sv->____joystickScrollSpeed;
}

void ScrollViewPatcherDynamic(ScrollView* sv) {
    m_fScrollTimer += Time::get_deltaTime();

    if (!isLinear) {
        m_fInertia = accel * m_fScrollTimer;
    } else {
        return;
    }

    m_fCustomSpeed = Mathf::Clamp(m_fInertia * m_fStockScrollSpeed, 0.0f, maxSpeed);
    sv->____joystickScrollSpeed = m_fCustomSpeed;
}

void ScrollViewPatcherConstant(LevelCollectionTableView* lctv) {
    TableView* tv = lctv->____tableView;
    ScrollView* sv = tv->GetComponent<ScrollView*>();

    if (StringW(sv->get_transform()->get_parent()->get_gameObject()->get_name()) == str) {
        sv->____joystickScrollSpeed = maxSpeed;
    }
}

void ScrollViewPatcherStock(LevelCollectionTableView* lctv) {
    TableView* tv = lctv->____tableView;
    ScrollView* sv = tv->GetComponent<ScrollView*>();

    if (StringW(sv->get_transform()->get_parent()->get_gameObject()->get_name()) == str) {
        sv->____joystickScrollSpeed = m_fStockScrollSpeed;
    }
}

void ResetInertia() {
    m_fInertia = 0.0f;
    m_fScrollTimer = 0.0f;
}

MAKE_EARLY_HOOK_MATCH(ScrollView_Awake, &ScrollView::Awake, void, ScrollView* self) {
    SetStockScrollSpeed(self);
    ScrollView_Awake(self);
}

MAKE_EARLY_HOOK_MATCH(LevelCollectionTableView_OnEnable, &LevelCollectionTableView::OnEnable, void, LevelCollectionTableView* self) {
    if (!isntStock) {
        ScrollViewPatcherStock(self);
        return;
    }
    if (isLinear && isntStock) {
        ScrollViewPatcherConstant(self);
    }
    LevelCollectionTableView_OnEnable(self);
}

MAKE_EARLY_HOOK_MATCH(
    ScrollView_HandleJoystickWasNotCenteredThisFrame, &ScrollView::HandleJoystickWasNotCenteredThisFrame, void, ScrollView* self, Vector2 deltaPos
) {
    if (!isLinear) {
        if (StringW(self->get_transform()->get_parent()->get_gameObject()->get_name()) == str && isntStock) {
            ScrollViewPatcherDynamic(self);
        }
    }

    ScrollView_HandleJoystickWasNotCenteredThisFrame(self, deltaPos);
}

MAKE_EARLY_HOOK_MATCH(ScrollView_HandleJoystickWasCenteredThisFrame, &ScrollView::HandleJoystickWasCenteredThisFrame, void, ScrollView* self) {
    if (!isLinear && StringW(self->get_transform()->get_parent()->get_gameObject()->get_name()) == str) {
        ResetInertia();
    }
    ScrollView_HandleJoystickWasCenteredThisFrame(self);
}
