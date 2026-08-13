// Custom awards — catalog + grant + session tracking
// Format: id|enabled|kind|freq|p1|p2|title|description
// See awards.md for kinds, filters, and limitations.

const int WE_MAX_AWARDS = 32;
const uint WE_AWARDS_THINK_MS = 500;
const String WE_AWARDS_PATH = "warfork-extended/awards.txt";
const String WE_AWARD_KEY_PREFIX = "award_";
const int WE_AWARD_ITEM_TAG_MAX = 64;

const int WE_AWARD_KIND_NONE = 0;
const int WE_AWARD_KIND_PING_HIGH = 1;
const int WE_AWARD_KIND_VICTIM_STREAK = 2;
const int WE_AWARD_KIND_REVENGE = 3;
const int WE_AWARD_KIND_SPEC_TIME = 4;
const int WE_AWARD_KIND_SUICIDE = 5;
const int WE_AWARD_KIND_FAST_DEATH = 6;
const int WE_AWARD_KIND_KILL_THEN_DIE = 7;
const int WE_AWARD_KIND_STILLNESS = 8;
const int WE_AWARD_KIND_MANUAL = 9;
const int WE_AWARD_KIND_KILL_STREAK = 10;
const int WE_AWARD_KIND_FIRST_BLOOD = 11;
const int WE_AWARD_KIND_ALIVE_TIME = 12;
const int WE_AWARD_KIND_DMG_DEALT = 13;
const int WE_AWARD_KIND_DMG_TAKEN = 14;
const int WE_AWARD_KIND_WEAPON_HIT = 15;
const int WE_AWARD_KIND_WEAPON_KILL = 16;
const int WE_AWARD_KIND_WEAPON_DEATH = 17;
const int WE_AWARD_KIND_SHOTS = 18;
const int WE_AWARD_KIND_HITS = 19;
const int WE_AWARD_KIND_KEY_PRESS = 20;
const int WE_AWARD_KIND_SPEED_KILL = 21;
const int WE_AWARD_KIND_FRAGS = 22;

const int WE_AWARD_FREQ_EVERY = 0;
const int WE_AWARD_FREQ_MAP = 1;
const int WE_AWARD_FREQ_ROUND = 2;
const int WE_AWARD_FREQ_ONCE = 3;

// p2 filter class for resolve
const int WE_AWARD_FILTER_NONE = 0;
const int WE_AWARD_FILTER_WEAPON = 1;
const int WE_AWARD_FILTER_AMMO = 2;
const int WE_AWARD_FILTER_KEY = 3;

const String WE_AWARDS_DEFAULT =
    "# id|enabled|kind|freq|p1|p2|title|description\n"
    + "# freq: every | map | round | once — see awards.md\n"
    + "# Duration params are seconds. ping_high p2=0 = spike (re-arm below).\n"
    + "# round = once per match playtime (not CA/bomb intra-match rounds).\n"
    + "lag_lord|1|ping_high|every|100|60|Lag Lord|Held ping over 100 for 60 seconds\n"
    + "dialup_diplomat|1|ping_high|round|250|0|Dial-up Diplomat|Ping spiked past 250\n"
    + "punching_bag|1|victim_streak|map|5|0|Punching Bag|Same player killed you 5 times in a row\n"
    + "the_student|1|revenge|map|3|0|The Student|Killed the player who got 3 consecutive kills on you\n"
    + "couch_potato|1|spec_time|map|180|0|Couch Potato|Spectated for 3 minutes\n"
    + "own_goal|1|suicide|round|1|0|Own Goal Enthusiast|You did that to yourself\n"
    + "spawn_tourist|1|fast_death|round|5|0|Spawn Tourist|Died within 5 seconds of spawning\n"
    + "glass_cannon|1|kill_then_die|every|3|0|Glass Cannon|Got a kill then died within 3 seconds\n"
    + "living_statue|1|stillness|map|30|0|Living Statue|Stood still while alive for 30 seconds\n"
    + "on_a_roll|1|kill_streak|round|5|0|On a Roll|5 kills without dying\n"
    + "first_blood|1|first_blood|round|0|0|First Blood|First kill of the match\n"
    + "survivor|1|alive_time|once|120|0|Survivor|Stayed alive for 2 minutes after spawning\n"
    + "participation|1|manual|every|0|0|Participation Trophy|Granted by an operator\n"
    + "rocket_man|1|weapon_kill|round|3|rocketlauncher|Rocket Man|3 kills with the rocket launcher\n"
    + "bunny|1|key_press|round|1000|jump|Bunny|Pressed jump 1000 times\n"
    + "bullet_sponge|1|dmg_taken|map|500|0|Bullet Sponge|Took 500 damage\n"
    + "spray|1|shots|round|100|bullets|Spray and Pray|Fired 100 machinegun bullets\n";

String[] weAwardId( WE_MAX_AWARDS );
String[] weAwardTitle( WE_MAX_AWARDS );
String[] weAwardDesc( WE_MAX_AWARDS );
int[] weAwardKind( WE_MAX_AWARDS );
int[] weAwardFreq( WE_MAX_AWARDS );
int[] weAwardP1( WE_MAX_AWARDS );
int[] weAwardP2( WE_MAX_AWARDS );
int weAwardCount = 0;

int[] weAwardBucketPing( WE_MAX_AWARDS );
int weAwardBucketPingCount = 0;
int[] weAwardBucketSpec( WE_MAX_AWARDS );
int weAwardBucketSpecCount = 0;
int[] weAwardBucketStill( WE_MAX_AWARDS );
int weAwardBucketStillCount = 0;
int[] weAwardBucketAlive( WE_MAX_AWARDS );
int weAwardBucketAliveCount = 0;
int[] weAwardBucketKill( WE_MAX_AWARDS );
int weAwardBucketKillCount = 0;
int[] weAwardBucketDmg( WE_MAX_AWARDS );
int weAwardBucketDmgCount = 0;
int[] weAwardBucketStats( WE_MAX_AWARDS );
int weAwardBucketStatsCount = 0;
int[] weAwardBucketKey( WE_MAX_AWARDS );
int weAwardBucketKeyCount = 0;

uint weAwardsNextThink = 0;
bool weAwardsFirstBloodTaken = false;

String[] weAwardMaskSteam( maxClients );
uint[] weAwardMapMask( maxClients );
uint[] weAwardRoundMask( maxClients );

class WE_AwardClient
{
    int lastKiller;
    int deathStreak;
    int suicideStreak;
    int killStreak;
    int fragCount;
    uint specSince;
    uint spawnTime;
    uint lastKillTime;
    float stillX;
    float stillY;
    float stillZ;
    uint stillSince;
    uint[] pingSince;
    uint pingArmedMask;
    uint aliveDoneMask;
    uint lastPressedKeys;
    int[] accum;      // per-award counters (dmg, hits, keys, weapon kills, …)
    int[] statsBase;  // accuracy baseline; -1 = unset
    bool statsReady;

    WE_AwardClient()
    {
        this.pingSince.resize( WE_MAX_AWARDS );
        this.accum.resize( WE_MAX_AWARDS );
        this.statsBase.resize( WE_MAX_AWARDS );
        this.Clear();
    }

    void Clear()
    {
        this.lastKiller = -1;
        this.deathStreak = 0;
        this.suicideStreak = 0;
        this.killStreak = 0;
        this.fragCount = 0;
        this.specSince = 0;
        this.spawnTime = 0;
        this.lastKillTime = 0;
        this.stillX = 0;
        this.stillY = 0;
        this.stillZ = 0;
        this.stillSince = 0;
        this.pingArmedMask = 0xffffffff;
        this.aliveDoneMask = 0;
        this.lastPressedKeys = 0;
        this.statsReady = false;
        for ( int i = 0; i < WE_MAX_AWARDS; i++ )
        {
            this.pingSince[i] = 0;
            this.accum[i] = 0;
            this.statsBase[i] = -1;
        }
    }

    void ResetPlaytimeCounters()
    {
        this.fragCount = 0;
        this.killStreak = 0;
        this.deathStreak = 0;
        this.suicideStreak = 0;
        this.lastKiller = -1;
        this.lastPressedKeys = 0;
        this.statsReady = false;
        for ( int i = 0; i < WE_MAX_AWARDS; i++ )
        {
            this.accum[i] = 0;
            this.statsBase[i] = -1;
        }
    }
}

WE_AwardClient[] weAwardClients( maxClients );

int WE_Awards_KindFromName( const String &in name )
{
    if ( name == "ping_high" )
        return WE_AWARD_KIND_PING_HIGH;
    if ( name == "victim_streak" )
        return WE_AWARD_KIND_VICTIM_STREAK;
    if ( name == "revenge" )
        return WE_AWARD_KIND_REVENGE;
    if ( name == "spec_time" )
        return WE_AWARD_KIND_SPEC_TIME;
    if ( name == "suicide" )
        return WE_AWARD_KIND_SUICIDE;
    if ( name == "fast_death" )
        return WE_AWARD_KIND_FAST_DEATH;
    if ( name == "kill_then_die" )
        return WE_AWARD_KIND_KILL_THEN_DIE;
    if ( name == "stillness" )
        return WE_AWARD_KIND_STILLNESS;
    if ( name == "manual" )
        return WE_AWARD_KIND_MANUAL;
    if ( name == "kill_streak" )
        return WE_AWARD_KIND_KILL_STREAK;
    if ( name == "first_blood" )
        return WE_AWARD_KIND_FIRST_BLOOD;
    if ( name == "alive_time" )
        return WE_AWARD_KIND_ALIVE_TIME;
    if ( name == "dmg_dealt" )
        return WE_AWARD_KIND_DMG_DEALT;
    if ( name == "dmg_taken" )
        return WE_AWARD_KIND_DMG_TAKEN;
    if ( name == "weapon_hit" )
        return WE_AWARD_KIND_WEAPON_HIT;
    if ( name == "weapon_kill" )
        return WE_AWARD_KIND_WEAPON_KILL;
    if ( name == "weapon_death" )
        return WE_AWARD_KIND_WEAPON_DEATH;
    if ( name == "shots" )
        return WE_AWARD_KIND_SHOTS;
    if ( name == "hits" )
        return WE_AWARD_KIND_HITS;
    if ( name == "key_press" )
        return WE_AWARD_KIND_KEY_PRESS;
    if ( name == "speed_kill" )
        return WE_AWARD_KIND_SPEED_KILL;
    if ( name == "frags" )
        return WE_AWARD_KIND_FRAGS;
    return WE_AWARD_KIND_NONE;
}

int WE_Awards_FreqFromName( const String &in name )
{
    if ( name == "every" )
        return WE_AWARD_FREQ_EVERY;
    if ( name == "map" )
        return WE_AWARD_FREQ_MAP;
    if ( name == "round" )
        return WE_AWARD_FREQ_ROUND;
    if ( name == "once" )
        return WE_AWARD_FREQ_ONCE;
    return -1;
}

int WE_Awards_FilterClass( int kind )
{
    if ( kind == WE_AWARD_KIND_DMG_DEALT || kind == WE_AWARD_KIND_DMG_TAKEN
         || kind == WE_AWARD_KIND_WEAPON_HIT || kind == WE_AWARD_KIND_WEAPON_KILL
         || kind == WE_AWARD_KIND_WEAPON_DEATH || kind == WE_AWARD_KIND_SPEED_KILL )
        return WE_AWARD_FILTER_WEAPON;
    if ( kind == WE_AWARD_KIND_SHOTS || kind == WE_AWARD_KIND_HITS )
        return WE_AWARD_FILTER_AMMO;
    if ( kind == WE_AWARD_KIND_KEY_PRESS )
        return WE_AWARD_FILTER_KEY;
    return WE_AWARD_FILTER_NONE;
}

bool WE_Awards_FilterRequired( int kind )
{
    return ( kind == WE_AWARD_KIND_WEAPON_HIT || kind == WE_AWARD_KIND_WEAPON_KILL
             || kind == WE_AWARD_KIND_WEAPON_DEATH || kind == WE_AWARD_KIND_SHOTS
             || kind == WE_AWARD_KIND_HITS || kind == WE_AWARD_KIND_KEY_PRESS );
}

bool WE_Awards_ValidId( const String &in id )
{
    if ( id.len() == 0 )
        return false;
    const String allowed = "0123456789abcdefghijklmnopqrstuvwxyz_";
    for ( uint i = 0; i < id.len(); i++ )
    {
        String ch = id.substr( i, 1 );
        bool ok = false;
        for ( uint j = 0; j < allowed.len(); j++ )
        {
            if ( allowed.substr( j, 1 ) == ch )
            {
                ok = true;
                break;
            }
        }
        if ( !ok )
            return false;
    }
    return true;
}

int WE_Awards_FindIndex( const String &in id )
{
    for ( int i = 0; i < weAwardCount; i++ )
    {
        if ( weAwardId[i] == id )
            return i;
    }
    return -1;
}

String WE_Awards_TitleForId( const String &in id )
{
    int idx = WE_Awards_FindIndex( id );
    if ( idx < 0 )
        return id;
    return weAwardTitle[idx];
}

String WE_Awards_Key( const String &in id )
{
    return WE_AWARD_KEY_PREFIX + id;
}

bool WE_Awards_InPlaytime()
{
    return ( match.getState() == MATCH_STATE_PLAYTIME );
}

int WE_Awards_ResolveKey( const String &in name )
{
    if ( name.isNumerical() )
    {
        int v = name.toInt();
        if ( v >= KEYICON_FORWARD && v < KEYICON_TOTAL )
            return v;
        return -1;
    }
    if ( WE_EqualsIgnoreCase( name, "forward" ) )
        return KEYICON_FORWARD;
    if ( WE_EqualsIgnoreCase( name, "backward" ) || WE_EqualsIgnoreCase( name, "back" ) )
        return KEYICON_BACKWARD;
    if ( WE_EqualsIgnoreCase( name, "left" ) )
        return KEYICON_LEFT;
    if ( WE_EqualsIgnoreCase( name, "right" ) )
        return KEYICON_RIGHT;
    if ( WE_EqualsIgnoreCase( name, "fire" ) || WE_EqualsIgnoreCase( name, "attack" ) )
        return KEYICON_FIRE;
    if ( WE_EqualsIgnoreCase( name, "jump" ) || WE_EqualsIgnoreCase( name, "space" ) )
        return KEYICON_JUMP;
    if ( WE_EqualsIgnoreCase( name, "crouch" ) || WE_EqualsIgnoreCase( name, "duck" ) )
        return KEYICON_CROUCH;
    if ( WE_EqualsIgnoreCase( name, "special" ) )
        return KEYICON_SPECIAL;
    return -1;
}

int WE_Awards_ResolveAmmoAlias( const String &in name )
{
    if ( WE_EqualsIgnoreCase( name, "gunblade" ) || WE_EqualsIgnoreCase( name, "gb" ) )
        return AMMO_GUNBLADE;
    if ( WE_EqualsIgnoreCase( name, "bullets" ) || WE_EqualsIgnoreCase( name, "bullet" )
         || WE_EqualsIgnoreCase( name, "machinegun" ) || WE_EqualsIgnoreCase( name, "mg" ) )
        return AMMO_BULLETS;
    if ( WE_EqualsIgnoreCase( name, "shells" ) || WE_EqualsIgnoreCase( name, "shell" )
         || WE_EqualsIgnoreCase( name, "riotgun" ) || WE_EqualsIgnoreCase( name, "rg" ) )
        return AMMO_SHELLS;
    if ( WE_EqualsIgnoreCase( name, "grenades" ) || WE_EqualsIgnoreCase( name, "grenade" )
         || WE_EqualsIgnoreCase( name, "grenadelauncher" ) || WE_EqualsIgnoreCase( name, "gl" ) )
        return AMMO_GRENADES;
    if ( WE_EqualsIgnoreCase( name, "rockets" ) || WE_EqualsIgnoreCase( name, "rocket" )
         || WE_EqualsIgnoreCase( name, "rocketlauncher" ) || WE_EqualsIgnoreCase( name, "rl" ) )
        return AMMO_ROCKETS;
    if ( WE_EqualsIgnoreCase( name, "plasma" ) || WE_EqualsIgnoreCase( name, "plasmagun" )
         || WE_EqualsIgnoreCase( name, "pg" ) )
        return AMMO_PLASMA;
    if ( WE_EqualsIgnoreCase( name, "lasers" ) || WE_EqualsIgnoreCase( name, "laser" )
         || WE_EqualsIgnoreCase( name, "lasergun" ) || WE_EqualsIgnoreCase( name, "lg" ) )
        return AMMO_LASERS;
    if ( WE_EqualsIgnoreCase( name, "bolts" ) || WE_EqualsIgnoreCase( name, "bolt" )
         || WE_EqualsIgnoreCase( name, "electrobolt" ) || WE_EqualsIgnoreCase( name, "eb" ) )
        return AMMO_BOLTS;
    if ( WE_EqualsIgnoreCase( name, "instas" ) || WE_EqualsIgnoreCase( name, "insta" )
         || WE_EqualsIgnoreCase( name, "instagun" ) )
        return AMMO_INSTAS;
    if ( WE_EqualsIgnoreCase( name, "weak_gunblade" ) )
        return AMMO_WEAK_GUNBLADE;
    if ( WE_EqualsIgnoreCase( name, "weak_bullets" ) )
        return AMMO_WEAK_BULLETS;
    if ( WE_EqualsIgnoreCase( name, "weak_shells" ) )
        return AMMO_WEAK_SHELLS;
    if ( WE_EqualsIgnoreCase( name, "weak_grenades" ) )
        return AMMO_WEAK_GRENADES;
    if ( WE_EqualsIgnoreCase( name, "weak_rockets" ) )
        return AMMO_WEAK_ROCKETS;
    if ( WE_EqualsIgnoreCase( name, "weak_plasma" ) )
        return AMMO_WEAK_PLASMA;
    if ( WE_EqualsIgnoreCase( name, "weak_lasers" ) )
        return AMMO_WEAK_LASERS;
    if ( WE_EqualsIgnoreCase( name, "weak_bolts" ) )
        return AMMO_WEAK_BOLTS;
    if ( WE_EqualsIgnoreCase( name, "weak_instas" ) )
        return AMMO_WEAK_INSTAS;
    return -1;
}

int WE_Awards_ResolveAmmo( const String &in query )
{
    if ( query.len() == 0 )
        return -1;
    if ( query.isNumerical() )
    {
        int tag = query.toInt();
        Item @item = @G_GetItem( tag );
        if ( @item != null && ( item.type & IT_AMMO ) != 0 )
            return item.tag;
        if ( tag > AMMO_NONE && tag < AMMO_TOTAL )
            return tag;
        return -1;
    }

    int alias = WE_Awards_ResolveAmmoAlias( query );
    if ( alias >= 0 )
        return alias;

    int matchCount = 0;
    int exactCount = 0;
    Item @found = null;
    Item @exact = null;
    for ( int i = 1; i < WE_AWARD_ITEM_TAG_MAX; i++ )
    {
        Item @item = @G_GetItem( i );
        if ( @item == null )
            continue;
        if ( ( item.type & IT_AMMO ) == 0 )
            continue;
        if ( item.name.len() == 0 )
            continue;
        if ( !WE_ContainsIgnoreCase( item.name, query )
             && !WE_ContainsIgnoreCase( item.shortName, query )
             && !WE_ContainsIgnoreCase( item.classname, query ) )
            continue;
        matchCount++;
        @found = @item;
        if ( WE_EqualsIgnoreCase( item.name, query )
             || WE_EqualsIgnoreCase( item.shortName, query )
             || WE_EqualsIgnoreCase( item.classname, query ) )
        {
            exactCount++;
            @exact = @item;
        }
    }
    if ( exactCount == 1 )
        return exact.tag;
    if ( matchCount == 1 )
        return found.tag;
    return -1;
}

int WE_Awards_ResolveWeapon( const String &in query )
{
    if ( query.len() == 0 )
        return -1;
    if ( query.isNumerical() )
    {
        int tag = query.toInt();
        if ( tag == 0 )
            return 0;
        Item @item = @G_GetItem( tag );
        if ( @item != null && ( item.type & IT_WEAPON ) != 0 )
            return item.tag;
        if ( tag >= WEAP_GUNBLADE && tag < WEAP_TOTAL )
            return tag;
        return -1;
    }

    // Common short names
    if ( WE_EqualsIgnoreCase( query, "gunblade" ) || WE_EqualsIgnoreCase( query, "gb" ) )
        return WEAP_GUNBLADE;
    if ( WE_EqualsIgnoreCase( query, "machinegun" ) || WE_EqualsIgnoreCase( query, "mg" ) )
        return WEAP_MACHINEGUN;
    if ( WE_EqualsIgnoreCase( query, "riotgun" ) || WE_EqualsIgnoreCase( query, "rg" ) )
        return WEAP_RIOTGUN;
    if ( WE_EqualsIgnoreCase( query, "grenadelauncher" ) || WE_EqualsIgnoreCase( query, "gl" ) )
        return WEAP_GRENADELAUNCHER;
    if ( WE_EqualsIgnoreCase( query, "rocketlauncher" ) || WE_EqualsIgnoreCase( query, "rl" )
         || WE_EqualsIgnoreCase( query, "rocket" ) )
        return WEAP_ROCKETLAUNCHER;
    if ( WE_EqualsIgnoreCase( query, "plasmagun" ) || WE_EqualsIgnoreCase( query, "pg" )
         || WE_EqualsIgnoreCase( query, "plasma" ) )
        return WEAP_PLASMAGUN;
    if ( WE_EqualsIgnoreCase( query, "lasergun" ) || WE_EqualsIgnoreCase( query, "lg" )
         || WE_EqualsIgnoreCase( query, "laser" ) )
        return WEAP_LASERGUN;
    if ( WE_EqualsIgnoreCase( query, "electrobolt" ) || WE_EqualsIgnoreCase( query, "eb" ) )
        return WEAP_ELECTROBOLT;
    if ( WE_EqualsIgnoreCase( query, "instagun" ) || WE_EqualsIgnoreCase( query, "insta" ) )
        return WEAP_INSTAGUN;

    int matchCount = 0;
    int exactCount = 0;
    Item @found = null;
    Item @exact = null;
    for ( int i = 1; i < WE_AWARD_ITEM_TAG_MAX; i++ )
    {
        Item @item = @G_GetItem( i );
        if ( @item == null )
            continue;
        if ( ( item.type & IT_WEAPON ) == 0 )
            continue;
        if ( item.name.len() == 0 )
            continue;
        if ( !WE_ContainsIgnoreCase( item.name, query )
             && !WE_ContainsIgnoreCase( item.shortName, query )
             && !WE_ContainsIgnoreCase( item.classname, query ) )
            continue;
        matchCount++;
        @found = @item;
        if ( WE_EqualsIgnoreCase( item.name, query )
             || WE_EqualsIgnoreCase( item.shortName, query )
             || WE_EqualsIgnoreCase( item.classname, query ) )
        {
            exactCount++;
            @exact = @item;
        }
    }
    if ( exactCount == 1 )
        return exact.tag;
    if ( matchCount == 1 )
        return found.tag;
    return -1;
}

// Resolve p2 filter. Returns false on invalid required/optional filter.
bool WE_Awards_ResolveP2( int kind, const String &in p2s, int &out p2 )
{
    p2 = 0;
    int filter = WE_Awards_FilterClass( kind );
    bool required = WE_Awards_FilterRequired( kind );

    if ( filter == WE_AWARD_FILTER_NONE )
    {
        if ( p2s.len() > 0 && p2s.isNumerical() )
            p2 = p2s.toInt();
        return true;
    }

    if ( p2s.len() == 0 || p2s == "0" )
    {
        if ( required )
            return false;
        p2 = 0;
        return true;
    }

    if ( filter == WE_AWARD_FILTER_WEAPON )
    {
        int tag = WE_Awards_ResolveWeapon( p2s );
        if ( tag < 0 )
            return false;
        if ( required && tag == 0 )
            return false;
        p2 = tag;
        return true;
    }
    if ( filter == WE_AWARD_FILTER_AMMO )
    {
        int tag = WE_Awards_ResolveAmmo( p2s );
        if ( tag < 0 )
            return false;
        p2 = tag;
        return true;
    }
    if ( filter == WE_AWARD_FILTER_KEY )
    {
        int tag = WE_Awards_ResolveKey( p2s );
        if ( tag < 0 )
            return false;
        p2 = tag;
        return true;
    }
    return false;
}

void WE_Awards_ClearCatalog()
{
    weAwardCount = 0;
    weAwardBucketPingCount = 0;
    weAwardBucketSpecCount = 0;
    weAwardBucketStillCount = 0;
    weAwardBucketAliveCount = 0;
    weAwardBucketKillCount = 0;
    weAwardBucketDmgCount = 0;
    weAwardBucketStatsCount = 0;
    weAwardBucketKeyCount = 0;
}

void WE_Awards_ClearFreqMasks()
{
    for ( int i = 0; i < maxClients; i++ )
    {
        weAwardMaskSteam[i] = "";
        weAwardMapMask[i] = 0;
        weAwardRoundMask[i] = 0;
    }
}

void WE_Awards_ClearRoundMasks()
{
    for ( int i = 0; i < maxClients; i++ )
        weAwardRoundMask[i] = 0;
}

int WE_Awards_FindMaskSlot( const String &in steamid )
{
    if ( steamid.len() == 0 )
        return -1;
    for ( int i = 0; i < maxClients; i++ )
    {
        if ( weAwardMaskSteam[i] == steamid )
            return i;
    }
    return -1;
}

int WE_Awards_AcquireMaskSlot( const String &in steamid )
{
    int slot = WE_Awards_FindMaskSlot( steamid );
    if ( slot >= 0 )
        return slot;
    for ( int i = 0; i < maxClients; i++ )
    {
        if ( weAwardMaskSteam[i].len() == 0 )
        {
            weAwardMaskSteam[i] = steamid;
            weAwardMapMask[i] = 0;
            weAwardRoundMask[i] = 0;
            return i;
        }
    }
    weAwardMaskSteam[0] = steamid;
    weAwardMapMask[0] = 0;
    weAwardRoundMask[0] = 0;
    return 0;
}

void WE_Awards_AddToBucketPing( int index )
{
    if ( weAwardBucketPingCount >= WE_MAX_AWARDS )
        return;
    weAwardBucketPing[weAwardBucketPingCount] = index;
    weAwardBucketPingCount++;
}

void WE_Awards_AddToBucketSpec( int index )
{
    if ( weAwardBucketSpecCount >= WE_MAX_AWARDS )
        return;
    weAwardBucketSpec[weAwardBucketSpecCount] = index;
    weAwardBucketSpecCount++;
}

void WE_Awards_AddToBucketStill( int index )
{
    if ( weAwardBucketStillCount >= WE_MAX_AWARDS )
        return;
    weAwardBucketStill[weAwardBucketStillCount] = index;
    weAwardBucketStillCount++;
}

void WE_Awards_AddToBucketAlive( int index )
{
    if ( weAwardBucketAliveCount >= WE_MAX_AWARDS )
        return;
    weAwardBucketAlive[weAwardBucketAliveCount] = index;
    weAwardBucketAliveCount++;
}

void WE_Awards_AddToBucketKill( int index )
{
    if ( weAwardBucketKillCount >= WE_MAX_AWARDS )
        return;
    weAwardBucketKill[weAwardBucketKillCount] = index;
    weAwardBucketKillCount++;
}

void WE_Awards_AddToBucketDmg( int index )
{
    if ( weAwardBucketDmgCount >= WE_MAX_AWARDS )
        return;
    weAwardBucketDmg[weAwardBucketDmgCount] = index;
    weAwardBucketDmgCount++;
}

void WE_Awards_AddToBucketStats( int index )
{
    if ( weAwardBucketStatsCount >= WE_MAX_AWARDS )
        return;
    weAwardBucketStats[weAwardBucketStatsCount] = index;
    weAwardBucketStatsCount++;
}

void WE_Awards_AddToBucketKey( int index )
{
    if ( weAwardBucketKeyCount >= WE_MAX_AWARDS )
        return;
    weAwardBucketKey[weAwardBucketKeyCount] = index;
    weAwardBucketKeyCount++;
}

void WE_Awards_AddToBuckets( int kind, int index )
{
    if ( kind == WE_AWARD_KIND_PING_HIGH )
        WE_Awards_AddToBucketPing( index );
    else if ( kind == WE_AWARD_KIND_SPEC_TIME )
        WE_Awards_AddToBucketSpec( index );
    else if ( kind == WE_AWARD_KIND_STILLNESS )
        WE_Awards_AddToBucketStill( index );
    else if ( kind == WE_AWARD_KIND_ALIVE_TIME )
        WE_Awards_AddToBucketAlive( index );
    else if ( kind == WE_AWARD_KIND_DMG_DEALT
              || kind == WE_AWARD_KIND_DMG_TAKEN
              || kind == WE_AWARD_KIND_WEAPON_HIT )
        WE_Awards_AddToBucketDmg( index );
    else if ( kind == WE_AWARD_KIND_SHOTS || kind == WE_AWARD_KIND_HITS )
        WE_Awards_AddToBucketStats( index );
    else if ( kind == WE_AWARD_KIND_KEY_PRESS )
        WE_Awards_AddToBucketKey( index );
    else if ( kind == WE_AWARD_KIND_VICTIM_STREAK
              || kind == WE_AWARD_KIND_REVENGE
              || kind == WE_AWARD_KIND_SUICIDE
              || kind == WE_AWARD_KIND_FAST_DEATH
              || kind == WE_AWARD_KIND_KILL_THEN_DIE
              || kind == WE_AWARD_KIND_KILL_STREAK
              || kind == WE_AWARD_KIND_FIRST_BLOOD
              || kind == WE_AWARD_KIND_WEAPON_KILL
              || kind == WE_AWARD_KIND_WEAPON_DEATH
              || kind == WE_AWARD_KIND_SPEED_KILL
              || kind == WE_AWARD_KIND_FRAGS )
        WE_Awards_AddToBucketKill( index );
}

bool WE_Awards_ParseField( const String &in line, uint pos, String &out field, uint &out nextPos )
{
    field = "";
    nextPos = pos;
    if ( pos > line.len() )
        return false;
    while ( pos < line.len() )
    {
        String ch = line.substr( pos, 1 );
        pos++;
        if ( ch == "|" )
        {
            nextPos = pos;
            return true;
        }
        field += ch;
    }
    nextPos = line.len() + 1;
    return true;
}

bool WE_Awards_ParseLine( const String &in line )
{
    if ( line.len() == 0 )
        return true;
    if ( line.substr( 0, 1 ) == "#" )
        return true;
    if ( weAwardCount >= WE_MAX_AWARDS )
        return false;

    uint pos = 0;
    String id;
    String enabled;
    String kindName;
    String field4;
    String field5;
    String field6;
    String field7;
    String field8;

    if ( !WE_Awards_ParseField( line, pos, id, pos ) )
        return false;
    if ( !WE_Awards_ParseField( line, pos, enabled, pos ) )
        return false;
    if ( !WE_Awards_ParseField( line, pos, kindName, pos ) )
        return false;
    if ( !WE_Awards_ParseField( line, pos, field4, pos ) )
        return false;
    if ( !WE_Awards_ParseField( line, pos, field5, pos ) )
        return false;
    if ( !WE_Awards_ParseField( line, pos, field6, pos ) )
        return false;
    if ( !WE_Awards_ParseField( line, pos, field7, pos ) )
        return false;
    WE_Awards_ParseField( line, pos, field8, pos );

    id = WE_Trim( id );
    enabled = WE_Trim( enabled );
    kindName = WE_Trim( kindName );
    field4 = WE_Trim( field4 );
    field5 = WE_Trim( field5 );
    field6 = WE_Trim( field6 );
    field7 = WE_Trim( field7 );
    field8 = WE_Trim( field8 );

    if ( enabled != "1" )
        return true;
    if ( !WE_Awards_ValidId( id ) )
        return false;
    if ( WE_Awards_FindIndex( id ) >= 0 )
        return false;

    int kind = WE_Awards_KindFromName( kindName );
    if ( kind == WE_AWARD_KIND_NONE )
        return false;

    String p1s;
    String p2s;
    String title;
    String desc;
    int freq = WE_AWARD_FREQ_EVERY;

    if ( field4.len() == 0 || field4.isNumerical() )
    {
        p1s = field4;
        p2s = field5;
        title = field6;
        desc = field7;
    }
    else
    {
        freq = WE_Awards_FreqFromName( field4 );
        if ( freq < 0 )
            return false;
        p1s = field5;
        p2s = field6;
        title = field7;
        desc = field8;
    }

    int p1 = 0;
    if ( p1s.len() > 0 && p1s.isNumerical() )
        p1 = p1s.toInt();

    int p2 = 0;
    if ( !WE_Awards_ResolveP2( kind, p2s, p2 ) )
        return false;

    if ( title.len() == 0 )
        title = id;

    int index = weAwardCount;
    weAwardId[index] = id;
    weAwardTitle[index] = title;
    weAwardDesc[index] = desc;
    weAwardKind[index] = kind;
    weAwardFreq[index] = freq;
    weAwardP1[index] = p1;
    weAwardP2[index] = p2;
    weAwardCount++;

    WE_Awards_AddToBuckets( kind, index );
    return true;
}

void WE_Awards_Load()
{
    WE_Awards_ClearCatalog();

    String data;
    if ( !WE_LoadFile( WE_AWARDS_PATH, data ) )
        return;

    String line;
    uint pos = 0;
    while ( WE_NextLine( data, pos, line, pos ) )
        WE_Awards_ParseLine( line );
}

void WE_Awards_SeedIfMissing()
{
    if ( WE_FileExists( WE_AWARDS_PATH ) )
        return;
    WE_WriteFileLocked( WE_AWARDS_PATH, "awards", WE_AWARDS_DEFAULT );
}

void WE_Awards_GrantIndex( Client @client, int index )
{
    if ( @client == null )
        return;
    if ( index < 0 || index >= weAwardCount )
        return;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return;

    String key = WE_Awards_Key( weAwardId[index] );
    String raw = WE_UserGet( steamid, key );
    int count = 0;
    if ( raw.len() > 0 && raw.isNumerical() )
        count = raw.toInt();
    if ( count < 0 )
        count = 0;
    count++;
    WE_UserSet( steamid, key, "" + count );

    String title = weAwardTitle[index];
    String awardMsg = S_COLOR_YELLOW + "Award: " + S_COLOR_WHITE + title
                      + S_COLOR_YELLOW + " (x" + count + ")";

    if ( we_awards_center_message.integer == 1 )
        client.addAward( awardMsg );

    if ( we_awards_chat_message.integer == 1 )
    {
        String prefix = WE_Theme_Prefix();
        Entity @selfEnt = @client.getEnt();
        if ( @selfEnt != null )
            G_PrintMsg( selfEnt, prefix + awardMsg + "\n" );

        String others = prefix + client.name + WE_MSG_AWARD_CHAT_GOT
                        + S_COLOR_YELLOW + title
                        + S_COLOR_YELLOW + " (x" + count + ")\n";
        for ( int i = 0; i < maxClients; i++ )
        {
            Client @other = @G_GetClient( i );
            if ( @other == null )
                continue;
            if ( other.playerNum == client.playerNum )
                continue;
            if ( other.state() <= CS_CONNECTING )
                continue;
            Entity @otherEnt = @other.getEnt();
            if ( @otherEnt == null )
                continue;
            G_PrintMsg( otherEnt, others );
        }
    }

    G_Print( WE_StripColors( client.name ) + " earned award: " + title + " (x" + count + ")\n" );
}

bool WE_Awards_TryGrantIndex( Client @client, int index )
{
    if ( @client == null )
        return false;
    if ( index < 0 || index >= weAwardCount )
        return false;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return false;

    int freq = weAwardFreq[index];
    uint bit = uint( 1 ) << uint( index );

    if ( freq == WE_AWARD_FREQ_ONCE )
    {
        String key = WE_Awards_Key( weAwardId[index] );
        String raw = WE_UserGet( steamid, key );
        int count = 0;
        if ( raw.len() > 0 && raw.isNumerical() )
            count = raw.toInt();
        if ( count > 0 )
            return false;
    }
    else if ( freq == WE_AWARD_FREQ_MAP || freq == WE_AWARD_FREQ_ROUND )
    {
        int slot = WE_Awards_AcquireMaskSlot( steamid );
        if ( slot < 0 )
            return false;
        if ( freq == WE_AWARD_FREQ_MAP )
        {
            if ( ( weAwardMapMask[slot] & bit ) != 0 )
                return false;
            weAwardMapMask[slot] |= bit;
        }
        else
        {
            if ( ( weAwardRoundMask[slot] & bit ) != 0 )
                return false;
            weAwardRoundMask[slot] |= bit;
        }
    }

    WE_Awards_GrantIndex( client, index );
    return true;
}

void WE_Awards_GrantId( Client @client, const String &in id )
{
    int index = WE_Awards_FindIndex( id );
    if ( index < 0 )
        return;
    WE_Awards_GrantIndex( client, index );
}

bool WE_Awards_RemoveIndex( Client @client, int index )
{
    if ( @client == null )
        return false;
    if ( index < 0 || index >= weAwardCount )
        return false;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return false;

    String key = WE_Awards_Key( weAwardId[index] );
    String raw = WE_UserGet( steamid, key );
    int count = 0;
    if ( raw.len() > 0 && raw.isNumerical() )
        count = raw.toInt();
    if ( count <= 0 )
        return false;

    count--;
    if ( count <= 0 )
    {
        String path = WE_UserPath( steamid );
        if ( path.len() == 0 )
            return false;
        String data;
        WE_LoadFile( path, data );
        data = WE_KvDelete( data, key );
        WE_WriteFileLocked( path, "user_" + steamid, data );
        count = 0;
    }
    else
    {
        WE_UserSet( steamid, key, "" + count );
    }

    String title = weAwardTitle[index];
    if ( count > 0 )
        WE_Print( client, S_COLOR_YELLOW + "Award removed: " + S_COLOR_WHITE + title
                             + S_COLOR_YELLOW + " (now x" + count + ")\n" );
    else
        WE_Print( client, S_COLOR_YELLOW + "Award removed: " + S_COLOR_WHITE + title + "\n" );
    return true;
}

void WE_Awards_ClearSlot( int playerNum )
{
    if ( playerNum < 0 || playerNum >= maxClients )
        return;
    weAwardClients[playerNum].Clear();
}

void WE_Awards_OnSpawn( WE_AwardClient @st )
{
    st.spawnTime = levelTime;
    st.stillSince = 0;
    st.aliveDoneMask = 0;
}

void WE_Awards_TryAccumGrant( Client @client, WE_AwardClient @st, int idx, int add )
{
    if ( add <= 0 )
        return;
    int need = weAwardP1[idx];
    if ( need <= 0 )
        return;
    st.accum[idx] += add;
    while ( st.accum[idx] >= need )
    {
        WE_Awards_TryGrantIndex( client, idx );
        st.accum[idx] -= need;
        // map/round/once: stop looping so we don't burn CPU after freq blocks
        if ( weAwardFreq[idx] != WE_AWARD_FREQ_EVERY )
        {
            st.accum[idx] = 0;
            break;
        }
    }
}

void WE_Awards_ThinkKeysClient( Client @client )
{
    if ( @client == null )
        return;
    if ( client.state() <= CS_CONNECTING )
        return;
    if ( WE_SteamId( client ).len() == 0 )
        return;

    int pn = client.playerNum;
    if ( pn < 0 || pn >= maxClients )
        return;

    WE_AwardClient @st = @weAwardClients[pn];
    uint keys = client.pressedKeys;
    uint prev = st.lastPressedKeys;
    uint risen = keys & ~prev;
    st.lastPressedKeys = keys;

    if ( risen == 0 )
        return;

    for ( int b = 0; b < weAwardBucketKeyCount; b++ )
    {
        int idx = weAwardBucketKey[b];
        int keyIcon = weAwardP2[idx];
        if ( keyIcon < KEYICON_FORWARD || keyIcon >= KEYICON_TOTAL )
            continue;
        uint bit = uint( 1 ) << uint( keyIcon );
        if ( ( risen & bit ) == 0 )
            continue;
        WE_Awards_TryAccumGrant( client, st, idx, 1 );
    }
}

void WE_Awards_ThinkStatsClient( Client @client )
{
    if ( @client == null )
        return;
    if ( client.state() <= CS_CONNECTING )
        return;
    if ( WE_SteamId( client ).len() == 0 )
        return;

    int pn = client.playerNum;
    if ( pn < 0 || pn >= maxClients )
        return;

    WE_AwardClient @st = @weAwardClients[pn];
    Entity @ent = @client.getEnt();
    if ( @ent == null )
        return;
    if ( ent.team == TEAM_SPECTATOR || ent.isGhosting() )
        return;

    for ( int b = 0; b < weAwardBucketStatsCount; b++ )
    {
        int idx = weAwardBucketStats[b];
        int ammo = weAwardP2[idx];
        if ( ammo <= AMMO_NONE )
            continue;

        int cur = 0;
        if ( weAwardKind[idx] == WE_AWARD_KIND_SHOTS )
            cur = client.stats.accuracyShots( ammo );
        else
            cur = client.stats.accuracyHits( ammo );

        if ( st.statsBase[idx] < 0 )
        {
            st.statsBase[idx] = cur;
            continue;
        }

        int delta = cur - st.statsBase[idx];
        if ( delta < 0 )
        {
            // stats cleared mid-match
            st.statsBase[idx] = cur;
            continue;
        }

        int need = weAwardP1[idx];
        if ( need <= 0 )
            continue;
        if ( delta < need )
            continue;

        WE_Awards_TryGrantIndex( client, idx );
        st.statsBase[idx] = cur;
        if ( weAwardFreq[idx] != WE_AWARD_FREQ_EVERY )
        {
            // keep base advanced; further deltas won't re-fire until reset
        }
    }
}

void WE_Awards_ThinkSlowClient( Client @client )
{
    if ( @client == null )
        return;
    if ( client.state() <= CS_CONNECTING )
        return;

    String steamid = WE_SteamId( client );
    if ( steamid.len() == 0 )
        return;

    Entity @ent = @client.getEnt();
    if ( @ent == null )
        return;

    int pn = client.playerNum;
    if ( pn < 0 || pn >= maxClients )
        return;

    WE_AwardClient @st = @weAwardClients[pn];
    bool spectating = ( ent.team == TEAM_SPECTATOR );
    bool ghosting = ent.isGhosting();

    if ( weAwardBucketSpecCount > 0 )
    {
        if ( spectating )
        {
            if ( st.specSince == 0 )
                st.specSince = levelTime;
            else
            {
                for ( int b = 0; b < weAwardBucketSpecCount; b++ )
                {
                    int idx = weAwardBucketSpec[b];
                    int needMs = weAwardP1[idx] * 1000;
                    if ( needMs <= 0 )
                        continue;
                    if ( levelTime >= st.specSince + uint( needMs ) )
                    {
                        WE_Awards_TryGrantIndex( client, idx );
                        st.specSince = levelTime;
                    }
                }
            }
        }
        else
        {
            st.specSince = 0;
        }
    }

    if ( spectating || ghosting )
    {
        st.stillSince = 0;
        for ( int i = 0; i < WE_MAX_AWARDS; i++ )
            st.pingSince[i] = 0;
        return;
    }

    if ( weAwardBucketPingCount > 0 )
    {
        int ping = client.ping;
        for ( int b = 0; b < weAwardBucketPingCount; b++ )
        {
            int idx = weAwardBucketPing[b];
            int thresh = weAwardP1[idx];
            int secs = weAwardP2[idx];
            uint bit = uint( 1 ) << uint( idx );

            if ( ping > thresh )
            {
                if ( secs <= 0 )
                {
                    if ( ( st.pingArmedMask & bit ) != 0 )
                    {
                        WE_Awards_TryGrantIndex( client, idx );
                        st.pingArmedMask &= ~bit;
                    }
                }
                else
                {
                    if ( st.pingSince[idx] == 0 )
                        st.pingSince[idx] = levelTime;
                    else if ( levelTime >= st.pingSince[idx] + uint( secs * 1000 ) )
                    {
                        WE_Awards_TryGrantIndex( client, idx );
                        st.pingSince[idx] = 0;
                    }
                }
            }
            else
            {
                st.pingSince[idx] = 0;
                if ( secs <= 0 )
                    st.pingArmedMask |= bit;
            }
        }
    }

    if ( weAwardBucketStillCount > 0 )
    {
        float x = ent.origin.x;
        float y = ent.origin.y;
        float z = ent.origin.z;
        if ( st.stillSince == 0 )
        {
            st.stillX = x;
            st.stillY = y;
            st.stillZ = z;
            st.stillSince = levelTime;
        }
        else if ( x != st.stillX || y != st.stillY || z != st.stillZ )
        {
            st.stillX = x;
            st.stillY = y;
            st.stillZ = z;
            st.stillSince = levelTime;
        }
        else
        {
            for ( int b = 0; b < weAwardBucketStillCount; b++ )
            {
                int idx = weAwardBucketStill[b];
                int needMs = weAwardP1[idx] * 1000;
                if ( needMs <= 0 )
                    continue;
                if ( levelTime >= st.stillSince + uint( needMs ) )
                {
                    WE_Awards_TryGrantIndex( client, idx );
                    st.stillSince = levelTime;
                }
            }
        }
    }

    if ( weAwardBucketAliveCount > 0 && st.spawnTime != 0 )
    {
        for ( int b = 0; b < weAwardBucketAliveCount; b++ )
        {
            int idx = weAwardBucketAlive[b];
            uint bit = uint( 1 ) << uint( idx );
            if ( ( st.aliveDoneMask & bit ) != 0 )
                continue;
            int needMs = weAwardP1[idx] * 1000;
            if ( needMs <= 0 )
                continue;
            if ( levelTime >= st.spawnTime + uint( needMs ) )
            {
                WE_Awards_TryGrantIndex( client, idx );
                st.aliveDoneMask |= bit;
            }
        }
    }

    if ( weAwardBucketStatsCount > 0 )
        WE_Awards_ThinkStatsClient( client );
}

void WE_Awards_Think()
{
    if ( we_feature_awards.integer != 1 )
        return;
    if ( !WE_Awards_InPlaytime() )
        return;

    bool needKeys = ( weAwardBucketKeyCount > 0 );
    bool needSlow = ( weAwardBucketPingCount > 0 || weAwardBucketSpecCount > 0
                      || weAwardBucketStillCount > 0 || weAwardBucketAliveCount > 0
                      || weAwardBucketStatsCount > 0 );
    if ( !needKeys && !needSlow )
        return;

    if ( needKeys )
    {
        for ( int i = 0; i < maxClients; i++ )
            WE_Awards_ThinkKeysClient( G_GetClient( i ) );
    }

    if ( !needSlow )
        return;
    if ( weAwardsNextThink > levelTime )
        return;
    weAwardsNextThink = levelTime + WE_AWARDS_THINK_MS;

    for ( int i = 0; i < maxClients; i++ )
        WE_Awards_ThinkSlowClient( G_GetClient( i ) );
}

void WE_Awards_OnDmg( Client @attackerClient, const String &args )
{
    if ( !WE_Awards_InPlaytime() )
        return;
    if ( weAwardBucketDmgCount == 0 )
        return;

    int victimEntNum = args.getToken( 0 ).toInt();
    float damage = args.getToken( 1 ).toFloat();
    if ( damage <= 0 )
        return;

    Entity @victimEnt = @G_GetEntity( victimEntNum );
    if ( @victimEnt == null || @victimEnt.client == null )
        return;

    Client @victim = @victimEnt.client;
    int attackerWeapon = 0;
    if ( @attackerClient != null )
        attackerWeapon = attackerClient.weapon;

    // Self-damage: still counts as taken; dealt only if attacker != victim for dealt awards
    bool selfDmg = ( @attackerClient == null || attackerClient.playerNum == victim.playerNum );

    for ( int b = 0; b < weAwardBucketDmgCount; b++ )
    {
        int idx = weAwardBucketDmg[b];
        int kind = weAwardKind[idx];
        int filter = weAwardP2[idx];

        if ( kind == WE_AWARD_KIND_DMG_DEALT )
        {
            if ( selfDmg || @attackerClient == null )
                continue;
            if ( WE_SteamId( attackerClient ).len() == 0 )
                continue;
            if ( filter != 0 && attackerWeapon != filter )
                continue;
            int apn = attackerClient.playerNum;
            if ( apn < 0 || apn >= maxClients )
                continue;
            WE_Awards_TryAccumGrant( attackerClient, weAwardClients[apn], idx, int( damage ) );
        }
        else if ( kind == WE_AWARD_KIND_DMG_TAKEN )
        {
            if ( WE_SteamId( victim ).len() == 0 )
                continue;
            if ( filter != 0 && attackerWeapon != filter )
                continue;
            int vpn = victim.playerNum;
            if ( vpn < 0 || vpn >= maxClients )
                continue;
            WE_Awards_TryAccumGrant( victim, weAwardClients[vpn], idx, int( damage ) );
        }
        else if ( kind == WE_AWARD_KIND_WEAPON_HIT )
        {
            if ( selfDmg || @attackerClient == null )
                continue;
            if ( WE_SteamId( attackerClient ).len() == 0 )
                continue;
            if ( filter == 0 || attackerWeapon != filter )
                continue;
            int apn = attackerClient.playerNum;
            if ( apn < 0 || apn >= maxClients )
                continue;
            WE_Awards_TryAccumGrant( attackerClient, weAwardClients[apn], idx, 1 );
        }
    }
}

void WE_Awards_OnKill( Client @attackerClient, const String &args )
{
    if ( !WE_Awards_InPlaytime() )
        return;
    if ( weAwardBucketKillCount == 0 )
        return;

    int victimEntNum = args.getToken( 0 ).toInt();
    Entity @victimEnt = @G_GetEntity( victimEntNum );
    if ( @victimEnt == null || @victimEnt.client == null )
        return;

    Client @victim = @victimEnt.client;
    if ( WE_SteamId( victim ).len() == 0 )
        return;

    int vpn = victim.playerNum;
    if ( vpn < 0 || vpn >= maxClients )
        return;

    WE_AwardClient @vst = @weAwardClients[vpn];

    bool suicide = ( @attackerClient == null || attackerClient.playerNum == victim.playerNum );
    int attackerNum = suicide ? -1 : attackerClient.playerNum;
    int attackerWeapon = 0;
    if ( !suicide && @attackerClient != null )
        attackerWeapon = attackerClient.weapon;

    vst.killStreak = 0;

    if ( !suicide && @attackerClient != null )
    {
        int apn = attackerClient.playerNum;
        if ( apn >= 0 && apn < maxClients && WE_SteamId( attackerClient ).len() > 0 )
        {
            WE_AwardClient @ast = @weAwardClients[apn];
            ast.lastKillTime = levelTime;
            ast.killStreak++;
            ast.fragCount++;

            Entity @attackerEnt = @attackerClient.getEnt();
            float horizSpeed = 0;
            if ( @attackerEnt != null )
            {
                Vec3 vel = attackerEnt.velocity;
                vel.z = 0;
                horizSpeed = vel.length();
            }

            for ( int b = 0; b < weAwardBucketKillCount; b++ )
            {
                int idx = weAwardBucketKill[b];
                int kind = weAwardKind[idx];

                if ( kind == WE_AWARD_KIND_REVENGE )
                {
                    if ( ast.lastKiller == victim.playerNum && ast.deathStreak >= weAwardP1[idx] )
                    {
                        WE_Awards_TryGrantIndex( attackerClient, idx );
                        ast.lastKiller = -1;
                        ast.deathStreak = 0;
                    }
                }
                else if ( kind == WE_AWARD_KIND_KILL_STREAK )
                {
                    if ( weAwardP1[idx] > 0 && ast.killStreak == weAwardP1[idx] )
                        WE_Awards_TryGrantIndex( attackerClient, idx );
                }
                else if ( kind == WE_AWARD_KIND_FIRST_BLOOD )
                {
                    if ( !weAwardsFirstBloodTaken )
                    {
                        if ( WE_Awards_TryGrantIndex( attackerClient, idx ) )
                            weAwardsFirstBloodTaken = true;
                    }
                }
                else if ( kind == WE_AWARD_KIND_WEAPON_KILL )
                {
                    if ( weAwardP2[idx] != 0 && attackerWeapon == weAwardP2[idx] )
                        WE_Awards_TryAccumGrant( attackerClient, ast, idx, 1 );
                }
                else if ( kind == WE_AWARD_KIND_SPEED_KILL )
                {
                    int needSpeed = weAwardP1[idx];
                    if ( needSpeed > 0 && horizSpeed >= float( needSpeed ) )
                    {
                        if ( weAwardP2[idx] == 0 || attackerWeapon == weAwardP2[idx] )
                            WE_Awards_TryGrantIndex( attackerClient, idx );
                    }
                }
                else if ( kind == WE_AWARD_KIND_FRAGS )
                {
                    if ( weAwardP1[idx] > 0 && ast.fragCount == weAwardP1[idx] )
                        WE_Awards_TryGrantIndex( attackerClient, idx );
                }
            }
        }
    }

    if ( suicide )
    {
        vst.lastKiller = -1;
        vst.deathStreak = 0;
        vst.suicideStreak++;
        for ( int b = 0; b < weAwardBucketKillCount; b++ )
        {
            int idx = weAwardBucketKill[b];
            if ( weAwardKind[idx] != WE_AWARD_KIND_SUICIDE )
                continue;
            if ( vst.suicideStreak >= weAwardP1[idx] )
            {
                WE_Awards_TryGrantIndex( victim, idx );
                vst.suicideStreak = 0;
            }
        }
        return;
    }

    vst.suicideStreak = 0;

    if ( vst.lastKiller == attackerNum )
        vst.deathStreak++;
    else
    {
        vst.lastKiller = attackerNum;
        vst.deathStreak = 1;
    }

    for ( int b = 0; b < weAwardBucketKillCount; b++ )
    {
        int idx = weAwardBucketKill[b];
        int kind = weAwardKind[idx];

        if ( kind == WE_AWARD_KIND_FAST_DEATH )
        {
            int needMs = weAwardP1[idx] * 1000;
            if ( needMs > 0 && vst.spawnTime != 0 && levelTime <= vst.spawnTime + uint( needMs ) )
                WE_Awards_TryGrantIndex( victim, idx );
        }
        else if ( kind == WE_AWARD_KIND_KILL_THEN_DIE )
        {
            int needMs = weAwardP1[idx] * 1000;
            if ( needMs > 0 && vst.lastKillTime != 0 && levelTime <= vst.lastKillTime + uint( needMs ) )
                WE_Awards_TryGrantIndex( victim, idx );
        }
        else if ( kind == WE_AWARD_KIND_VICTIM_STREAK )
        {
            if ( vst.deathStreak == weAwardP1[idx] )
                WE_Awards_TryGrantIndex( victim, idx );
        }
        else if ( kind == WE_AWARD_KIND_WEAPON_DEATH )
        {
            if ( weAwardP2[idx] != 0 && attackerWeapon == weAwardP2[idx] )
                WE_Awards_TryAccumGrant( victim, vst, idx, 1 );
        }
    }
}

void WE_Awards_OnEnterGame( Client @client )
{
    if ( @client == null )
        return;

    int pn = client.playerNum;
    if ( pn < 0 || pn >= maxClients )
        return;
    weAwardClients[pn].Clear();
}

void WE_Awards_OnDisconnect( Client @client )
{
    if ( @client == null )
        return;
    WE_Awards_ClearSlot( client.playerNum );
}

void WE_Awards_OnScoreEvent( Client @client, const String &score_event, const String &args )
{
    if ( we_feature_awards.integer != 1 )
        return;

    if ( score_event == "kill" )
    {
        WE_Awards_OnKill( client, args );
        return;
    }
    if ( score_event == "dmg" )
    {
        WE_Awards_OnDmg( client, args );
        return;
    }
    if ( score_event == "enterGame" )
    {
        WE_Awards_OnEnterGame( client );
        return;
    }
    if ( score_event == "disconnect" )
    {
        WE_Awards_OnDisconnect( client );
        return;
    }
}

void WE_Awards_OnMatchStateStarted()
{
    if ( we_feature_awards.integer != 1 )
        return;
    if ( match.getState() != MATCH_STATE_PLAYTIME )
        return;

    WE_Awards_ClearRoundMasks();
    weAwardsFirstBloodTaken = false;
    for ( int i = 0; i < maxClients; i++ )
        weAwardClients[i].ResetPlaytimeCounters();
}

void WE_Awards_OnPlayerRespawn( Entity @ent, int old_team, int new_team )
{
    if ( we_feature_awards.integer != 1 )
        return;
    if ( @ent == null || @ent.client == null )
        return;
    if ( ent.isGhosting() )
        return;
    if ( ent.team == TEAM_SPECTATOR )
        return;

    Client @client = @ent.client;
    int pn = client.playerNum;
    if ( pn < 0 || pn >= maxClients )
        return;

    WE_Awards_OnSpawn( weAwardClients[pn] );
}

void WE_Awards_Init()
{
    if ( we_feature_awards.integer != 1 )
        return;

    WE_Awards_SeedIfMissing();
    WE_Awards_Load();
    weAwardsNextThink = 0;
    weAwardsFirstBloodTaken = false;
    WE_Awards_ClearFreqMasks();

    for ( int i = 0; i < maxClients; i++ )
        weAwardClients[i].Clear();
}

void WE_Awards_Register()
{
    WE_Hooks_AddThinkAfter( @WE_Awards_Think );
    WE_Hooks_AddScoreEventAfter( @WE_Awards_OnScoreEvent );
    WE_Hooks_AddMatchStateStartedAfter( @WE_Awards_OnMatchStateStarted );
    WE_Hooks_AddPlayerRespawnAfter( @WE_Awards_OnPlayerRespawn );
}
