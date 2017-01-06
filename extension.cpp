#include "extension.h"

#include <ISDKTools.h>
#include <icvar.h>

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
ISDKTools *g_pSDKTools = NULL;
IGameConfig *g_pGameConf = NULL;
IServer *g_pServer = NULL;
ICvar *icvar = NULL;

ConVar g_AddonsEclipse("l4d2_addons_eclipse", "-1", FCVAR_SPONLY|FCVAR_NOTIFY, "Addons Manager(-1: use addonconfig; 0/1: override addonconfig)");

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

class BaseAccessor : public IConCommandBaseAccessor
{
public:
	bool RegisterConCommandBase(ConCommandBase *pCommandBase)
	{
		/* Always call META_REGCVAR instead of going through the engine. */
		return META_REGCVAR(pCommandBase);
	}
} s_BaseAccessor;

bool AddonDisabler::SDK_OnMetamodLoad( ISmmAPI *ismm, char *error, size_t maxlength, bool late )
{
	size_t maxlen=maxlength;
	GET_V_IFACE_CURRENT(GetEngineFactory, icvar, ICvar, CVAR_INTERFACE_VERSION);
	g_pCVar = icvar;
	ConVar_Register(0, &s_BaseAccessor);
	return true;
}

void AddonDisabler::SDK_OnAllLoaded()
{
	SM_GET_LATE_IFACE(SDKTOOLS, g_pSDKTools);
 
 	if (!g_pSDKTools)
 	{
		L4D_DEBUG_LOG("Failed to load sdktools");
 		return;
	}
	g_pServer = g_pSDKTools->GetIServer();
	L4D_DEBUG_LOG("Address of IServer is %p", g_pServer);
	g_AddonsEclipse.InstallChangeCallback(::OnAddonsEclipseChanged);
	AddonsDisabler::AddonsEclipse = g_AddonsEclipse.GetInt();
	g_PatchManager.Register(new AutoPatch<Detours::CBaseServer>());
}

void AddonDisabler::SDK_OnUnload()
{
	ConVar_Unregister();
	AddonsDisabler::Unpatch();
	g_PatchManager.UnregisterAll();
	gameconfs->CloseGameConfigFile(g_pGameConf);
	forwards->ReleaseForward(g_pFwdAddonsDisabler);
}
