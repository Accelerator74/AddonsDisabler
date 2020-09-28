#include "extension.h"

#include "codepatch/patchmanager.h"
#include "codepatch/autopatch.h"

#include "addons_disabler.h"

/**
 * @file extension.cpp
 * @brief Implement extension code here.
 */

AddonDisabler g_AddonsDisabler;		/**< Global singleton for extension's main interface */
SMEXT_LINK(&g_AddonsDisabler);

IForward *g_pFwdAddonsDisabler = NULL;
IGameConfig *g_pGameConf = NULL;
PatchManager g_PatchManager;

bool AddonDisabler::SDK_OnLoad(char *error, size_t maxlength, bool late)
{
	if (strcmp(g_pSM->GetGameFolderName(), "left4dead2") != 0)
	{
		snprintf(error, maxlength, "Cannot Load Ext on mods other than L4D2");
		return false;
	}
	char ConfigError[128];
	if(!gameconfs->LoadGameConfigFile("AddonsDisabler", &g_pGameConf, ConfigError, sizeof(ConfigError)))
	{
		if (error)
		{
			snprintf(error, maxlength, "AddonsDisabler.txt error : %s", ConfigError);
		}
		return false;
	}
	g_pFwdAddonsDisabler = forwards->CreateForward("L4D2_OnClientDisableAddons", ET_Event, 1, /*types*/NULL, Param_String);
	Detour::Init(g_pSM->GetScriptingEngine(), g_pGameConf);

	return true;
}

void AddonDisabler::SDK_OnAllLoaded()
{
	AddonsDisabler::Patch();
	g_PatchManager.Register(new AutoPatch<Detours::CBaseServer>());
}

void AddonDisabler::SDK_OnUnload()
{
	AddonsDisabler::Unpatch();
	g_PatchManager.UnregisterAll();
	gameconfs->CloseGameConfigFile(g_pGameConf);
	forwards->ReleaseForward(g_pFwdAddonsDisabler);
}
