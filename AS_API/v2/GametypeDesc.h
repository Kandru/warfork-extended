/* funcdefs */

/**
 * GametypeDesc
 */
class GametypeDesc
{
public:
	/* object properties */
	uint spawnableItemsMask;
	uint respawnableItemsMask;
	uint dropableItemsMask;
	uint pickableItemsMask;
	bool isTeamBased;
	bool isRace;
	bool isTutorial;
	bool inverseScore;
	bool hasChallengersQueue;
	bool hasChallengersRoulette;
	int maxPlayersPerTeam;
	int ammoRespawn;
	int armorRespawn;
	int weaponRespawn;
	int healthRespawn;
	int powerupRespawn;
	int megahealthRespawn;
	int ultrahealthRespawn;
	bool readyAnnouncementEnabled;
	bool scoreAnnouncementEnabled;
	bool countdownEnabled;
	bool mathAbortDisabled;
	bool matchAbortDisabled;
	bool shootingDisabled;
	bool infiniteAmmo;
	bool canForceModels;
	bool canShowMinimap;
	bool teamOnlyMinimap;
	int spawnpointRadius;
	bool customDeadBodyCam;
	bool removeInactivePlayers;
	bool mmCompatible;
	uint numBots;
	bool dummyBots;
	uint forceTeamHumans;
	uint forceTeamBots;
	bool disableObituaries;

	/* object behaviors */

	/* object methods */
	const String @ get_name() const;
	const String @ get_title() const;
	void set_title( const String &in );
	const String @ get_version() const;
	void set_version( const String &in );
	const String @ get_author() const;
	void set_author( const String &in );
	const String @ get_manifest() const;
	void setTeamSpawnsystem( int team, int spawnsystem, int wave_time, int wave_maxcount, bool deadcam );
	bool get_isInstagib() const;
	bool get_useSteamAuth() const;
	bool get_hasFallDamage() const;
	bool get_hasSelfDamage() const;
	bool get_isInvidualGameType() const;
};

