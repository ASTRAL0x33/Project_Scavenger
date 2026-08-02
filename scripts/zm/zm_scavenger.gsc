/*
"Project Scavenger" - TranZit / Die Rise / Buried
v1.2

Made by: NickB_05

 This script allows you to carry every single buildable part from the
 victis line up of maps, similar to the mob, origins and bo3s part carrying
 system

 My objective is to make the part carrying system as much similar as mobs and
 origins as possible, having similar ui stuff, with the parts being displayed
 in the leaderboard, for now it isnt like that since im still learning how to
 display the ui, but atleast the concept its 100% similar to the original

 The only parts that you cant carry all in one are the elevator key,
 prision key, booze, candies and weapon chalks, mostly to keep the mechanics
 and... i have some ideas for the elevator key... enjoy the script!

 DISCLAMER: If you're going to use this script for a different project please
 credit my work, since it took me atleast a month to finish this project
 
v1.1 Patch Fixes made by: SyntaXError
v1.2 Patch Fixes made by: NickB_05
v1.3 Patch Fixes

Added the table build-selection system so double-tapping Use
cycles between multiple ready buildables sharing the same table.

Added the Die Rise elevator key system so the key only auto-refills
while looking directly at an elevator callbox.

Added the elevator key removal when looking away from the callbox.

Added the ability to hold Use on a callbox for 0.5s to lock/unlock
the elevator's current position.
*/

#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\_utility;

#define MC_BUILD_RADIUS_SQ 7000 // horizontal distance (X/Y) for most buildable areas
#define MC_BUILD_RADIUS_SQ_TIGHT 2500 //Hatch/ladder/plow – positioned more tightly to avoid stepping on the window repair or other nearby items
#define MC_HEIGHT_TOLERANCE 82 // Maximum permitted height difference (Z) – filters out different floors (usually spaced 128+ units apart) without disrupting standard construction
#define MC_DEFAULT_BUILD_TIME 3000 // ms, is used if the stub does not bring its own usetime

init()
{
    map = getdvar( "mapname" );

    if ( map != "zm_transit" && map != "zm_highrise" && map != "zm_buried" )
        return;

    if ( map == "zm_buried" )
    {
        func = getfunction( "maps/mp/zombies/_zm_buildables_pooled", "pooledbuildable_stub_for_piece" );
        if ( isdefined( func ) )
        {
            replacefunc( func, ::custom_pooledbuildable_stub_for_piece );
        }
    }

    level.mc_is_buried = ( map == "zm_buried" );
    level.mc_is_highrise = ( map == "zm_highrise" );

    level.mc_debug = 0;
    if ( getdvar( "mc_debug" ) == "1" )
        level.mc_debug = 1;

    level.mc_gated_buildables = [];
    level.mc_gated_buildables["jetgun_zm"] = 1;
    level.mc_gated_buildables["turbine"] = 1;
    level.mc_gated_buildables["riotshield_zm"] = 1;
    level.mc_gated_buildables["turret"] = 1;
    level.mc_gated_buildables["electric_trap"] = 1;
    level.mc_gated_buildables["pap"] = 1;
    level.mc_gated_buildables["sq_common"] = 1;
    level.mc_gated_buildables["springpad_zm"] = 1; 
    level.mc_gated_buildables["slipgun_zm"] = 1;
    level.mc_gated_buildables["headchopper_zm"] = 1;
    level.mc_gated_buildables["subwoofer_zm"] = 1;
    level.mc_gated_buildables["buried_sq_bt_m_tower"] = 1;
    level.mc_gated_buildables["buried_sq_bt_r_tower"] = 1;

    if ( level.mc_is_buried )
        level.mc_gated_buildables["powerswitch"] = 1;

    level.mc_immediate_buildables = [];
    level.mc_immediate_buildables["cattlecatcher"] = 1;
    level.mc_immediate_buildables["bushatch"] = 1;
    level.mc_immediate_buildables["dinerhatch"] = 1;
    level.mc_immediate_buildables["busladder"] = 1;

    level thread on_player_connect();
    level thread mc_debug_print_names();
    level thread mc_setup_custom_prompts();
}

mc_debug_print_names()
{
    level waittill( "buildables_setup" );

    if ( !level.mc_debug )
        return;

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) )
            continue;

        name = stub.buildablezone.buildable_name;
        gated = isdefined( level.mc_gated_buildables[name] );
        immediate = isdefined( level.mc_immediate_buildables[name] );
        println( "[mc_debug] buildable_name = " + name + "  (gated=" + gated + ", immediate=" + immediate + ")" );
    }
}

mc_display_name( name )
{
    switch ( name )
    {
        case "riotshield_zm":
            return "Zombie Shield";
        case "jetgun_zm":
            return "Jet Gun";
        case "turbine":
            return "Turbine";
        case "turret":
            return "Turret";
        case "electric_trap":
            return "Electric Trap";
        case "powerswitch":
            return "Power Switch";
        case "pap":
            return "Pack-a-Punch";
        case "sq_common":
            return "Nav-Card";
        case "springpad_zm":
            return "Trample Steam";
        case "slipgun_zm":
            return "Sliquifier";
        case "headchopper_zm":
            return "Head Chopper";
        case "subwoofer_zm":
        case "subwoofer":
            return "Resonator";
        case "buried_sq_bt_m_tower":
            return "Gallows";
        case "buried_sq_bt_r_tower":
            return "Guillotine";
        case "cattlecatcher":
            return "Cattle Catcher";
        case "bushatch":
            return "Bus Hatch";
        case "dinerhatch":
            return "Diner Hatch";
        case "busladder":
            return "Bus Ladder";
    }

    return name;
}

mc_representative_icon( name )
{
    switch ( name )
    {
        case "riotshield_zm":
            return "riotshield_zm_icon";
        case "jetgun_zm":
            return "jetgun_zm_icon";
        case "turbine":
            return "turbine_zm_icon";
        case "turret":
            return "turret_zm_icon";
        case "electric_trap":
            return "etrap_zm_icon";
        case "powerswitch":
            return "zm_hud_icon_panel";
        case "pap":
            return "zm_hud_icon_papbody";
        case "sq_common":
            return "zm_hud_icon_sq_powerbox";
        case "springpad_zm":
            return "zom_hud_trample_steam_complete";
        case "slipgun_zm":
            return "zom_hud_icon_buildable_slip_ext";
        case "headchopper_zm":
            return "zom_hud_icon_buildable_chop_a";
        case "subwoofer_zm":
        case "subwoofer":
            return "zom_hud_icon_buildable_woof_speaker";
        case "buried_sq_bt_m_tower":
            return "zm_hud_icon_battery";
        case "buried_sq_bt_r_tower":
            return "zm_hud_icon_sq_meteor";
        case "cattlecatcher":
            return "zm_hud_icon_plow";
        case "bushatch":
            return "zm_hud_icon_hatch";
        case "dinerhatch":
            return "zm_hud_icon_hatch";
        case "busladder":
            return "zm_hud_icon_ladder";
    }

    return undefined;
}

mc_show_piece_notify( display_name, hud_icon, progress_text )
{
    self endon( "disconnect" );

    if ( isdefined( self.mc_notify_icon ) )
        self.mc_notify_icon destroy();

    if ( isdefined( self.mc_notify_text ) )
        self.mc_notify_text destroy();

    icon = newclienthudelem( self );
    icon.horzalign = "left";
    icon.vertalign = "top";
    icon.alignx = "right";
    icon.aligny = "top";
    icon.x = -12;
    icon.y = -23;
    icon.alpha = 1;

    if ( isdefined( hud_icon ) )
        icon setshader( hud_icon, 20, 20 );

    text = newclienthudelem( self );
    text.horzalign = "left";
    text.vertalign = "top";
    text.alignx = "left";
    text.aligny = "top";
    text.x = -8;
    text.y = -23;
    text.fontscale = 1.3;
    text.alpha = 1;
    text settext( display_name + " (" + progress_text + ")" );

    self.mc_notify_icon = icon;
    self.mc_notify_text = text;

    icon thread mc_fade_and_destroy( 2.5 );
    text thread mc_fade_and_destroy( 2.5 );
}

mc_fade_and_destroy( delay )
{
    self endon( "death" );
    wait delay;

    if ( !isdefined( self ) )
        return;

    self fadeovertime( 0.5 );
    self.alpha = 0;
    wait 0.5;

    if ( isdefined( self ) )
        self destroy();
}

mc_is_ours( name )
{
    return isdefined( level.mc_gated_buildables[name] ) || isdefined( level.mc_immediate_buildables[name] );
}

mc_is_gated( name )
{
    return isdefined( level.mc_gated_buildables[name] );
}

mc_in_range( origin, target, radius_sq )
{
    if ( distance2dsquared( origin, target ) >= radius_sq )
        return false;

    zdiff = origin[2] - target[2];

    if ( zdiff < 0 )
        zdiff = zdiff * -1;

    if ( zdiff > MC_HEIGHT_TOLERANCE )
        return false;

    return true;
}

mc_build_radius_sq( name )
{
    switch ( name )
    {
        case "bushatch":
        case "dinerhatch":
        case "busladder":
        case "cattlecatcher":
            return MC_BUILD_RADIUS_SQ_TIGHT;
    }

    return MC_BUILD_RADIUS_SQ;
}

mc_setup_custom_prompts()
{
    level waittill( "buildables_setup" );

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) )
            continue;

        if ( !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        stub.mc_original_prompt = stub.custom_buildablestub_update_prompt;
        stub.custom_buildablestub_update_prompt = ::mc_custom_prompt;
    }
}

mc_buried_find_ready_target()
{
    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.table_built ) && stub.table_built )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        zone = stub.buildablezone;
        deliverable = self mc_get_deliverable_pieces( zone );
        can_attempt = false;

        if ( mc_is_gated( zone.buildable_name ) )
            can_attempt = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
        else
            can_attempt = deliverable.size > 0;

        if ( can_attempt )
            return stub;
    }

    return undefined;
}

mc_custom_prompt( player )
{
    if ( isdefined( self.built ) && self.built )
        return true;

    if ( isdefined( self.mc_original_prompt ) && !( self [[ self.mc_original_prompt ]]( player ) ) )
        return false;

    if ( !isdefined( self.buildablezone ) )
        return true;

    zone = self.buildablezone;

    if ( !mc_is_ours( zone.buildable_name ) )
        return true;

    deliverable = player mc_get_deliverable_pieces( zone );
    ready = false;

    if ( mc_is_gated( zone.buildable_name ) )
        ready = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
    else
        ready = deliverable.size > 0;

    display_name = zone.buildable_name;

    if ( !ready && level.mc_is_buried )
    {
        target = player mc_buried_find_ready_target();

        if ( isdefined( target ) )
        {
            ready = true;
            display_name = target.buildablezone.buildable_name;
        }
    }

    if ( ready )
    {
        if ( isdefined( player.mc_preferred_buildable ) && player.mc_preferred_buildable != zone.buildable_name )
        {
            self.hint_string = "";
            self.cursor_hint = "HINT_NOICON";
            return false;
        }
        
        if ( isdefined( level.zombie_buildables[self.equipname] ) && isdefined( level.zombie_buildables[self.equipname].hint ) )
            self.hint_string = level.zombie_buildables[self.equipname].hint;
			
        self.cursor_hint = "HINT_NOICON";
        return false;
    }

    return true;
}

on_player_connect()
{
    level endon( "end_game" );

    while ( true )
    {
        level waittill( "connected", player );
        player thread player_collect_and_build();
        
        if ( isdefined( level.mc_is_highrise ) && level.mc_is_highrise )
        {
            player thread mc_infinite_elevator_key_think();
            player thread mc_elevator_lock_think_player();
        }
    }
}

mc_get_stub_origin( stub )
{
    if ( isdefined( stub.originfunc ) )
        return stub [[ stub.originfunc ]]();

    return stub.origin;
}

mc_count_remaining( zone )
{
    remaining = 0;

    for ( i = 0; i < zone.pieces.size; i++ )
    {
        if ( !( isdefined( zone.pieces[i].built ) && zone.pieces[i].built ) )
            remaining++;
    }

    return remaining;
}

mc_piece_key( piece )
{
    return piece.buildablename + "|" + piece.modelname;
}

mc_get_deliverable_pieces( zone )
{
    result = [];
    used = [];

    for ( i = 0; i < zone.pieces.size; i++ )
    {
        if ( isdefined( zone.pieces[i].built ) && zone.pieces[i].built )
            continue;

        key = mc_piece_key( zone.pieces[i] );

        pool = 0;
        if ( isdefined( self.mc_have[key] ) )
            pool = self.mc_have[key];

        consumed = 0;
        if ( isdefined( used[key] ) )
            consumed = used[key];

        if ( pool - consumed > 0 )
        {
            result[result.size] = zone.pieces[i];
            used[key] = consumed + 1;
        }
    }

    return result;
}

player_collect_and_build()
{
    self endon( "disconnect" );
    level waittill( "buildables_setup" );

    self.mc_have = [];

    self thread mc_collect_loop();
    self thread mc_deliver_loop();
    
    if ( isdefined( level.mc_is_buried ) && level.mc_is_buried )
    {
        self thread mc_build_selection_loop();
    }
}

mc_collect_loop()
{
    self endon( "disconnect" );

    while ( true )
    {
        self mc_try_collect();
        wait 0.05;
    }
}

mc_deliver_loop()
{
    self endon( "disconnect" );

    while ( true )
    {
        if ( level.mc_is_buried )
            self mc_try_deliver_buried();
        else
            self mc_try_deliver_default();

        wait 0.1;
    }
}

mc_try_collect()
{
    held_pieces = self player_get_buildable_pieces();

    if ( held_pieces.size == 0 )
        return;

    foreach ( held in held_pieces )
    {
        if ( !isdefined( held ) )
            continue;

        candidates = [];

        foreach ( stub in level.buildable_stubs )
        {
            if ( !isdefined( stub.buildablezone ) || !isdefined( stub.buildablezone.pieces ) )
                continue;

            if ( !mc_is_ours( stub.buildablezone.buildable_name ) )
                continue;

            if ( isdefined( stub.built ) && stub.built )
                continue;

            if ( stub.buildablezone buildable_has_piece( held ) )
                candidates[candidates.size] = stub;
        }

        if ( candidates.size == 0 )
            continue;

        key = mc_piece_key( held );
        count = 0;

        if ( isdefined( self.mc_have[key] ) )
            count = self.mc_have[key];

        self.mc_have[key] = count + 1;
        self.mc_last_pickup_time = gettime();
        nearest = candidates[0];
        nearest_dist = distancesquared( self.origin, mc_get_stub_origin( nearest ) );

        for ( i = 1; i < candidates.size; i++ )
        {
            d = distancesquared( self.origin, mc_get_stub_origin( candidates[i] ) );

            if ( d < nearest_dist )
            {
                nearest_dist = d;
                nearest = candidates[i];
            }
        }

        names = mc_display_name( candidates[0].buildablezone.buildable_name );

        for ( i = 1; i < candidates.size; i++ )
            names = names + " / " + mc_display_name( candidates[i].buildablezone.buildable_name );

        if ( level.mc_debug )
            println( "[mc_debug] piece " + held.buildablename + "/" + held.modelname + " -> candidates=" + candidates.size + " (available for everyone, no random values)" );

        self mc_show_piece_notify( names, mc_representative_icon( nearest.buildablezone.buildable_name ), self mc_progress_text( nearest.buildablezone ) );

        self player_destroy_piece( held );
    }
}

mc_try_deliver_default()
{
    if ( isdefined( self.mc_last_pickup_time ) && gettime() - self.mc_last_pickup_time < 400 )
        return;

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !isdefined( stub.buildablezone.pieces ) )
            continue;

        if ( !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        zone = stub.buildablezone;
        stub_origin = mc_get_stub_origin( stub );

        if ( !mc_in_range( self.origin, stub_origin, mc_build_radius_sq( zone.buildable_name ) ) )
            continue;

        if ( !self usebuttonpressed() )
            continue;

        deliverable = self mc_get_deliverable_pieces( zone );
        can_attempt = false;

        if ( mc_is_gated( zone.buildable_name ) )
            can_attempt = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
        else
            can_attempt = deliverable.size > 0;

        if ( !can_attempt )
            continue;

        if ( isdefined( self.mc_preferred_buildable ) && self.mc_preferred_buildable != zone.buildable_name )
            continue;

        if ( isdefined( stub.mc_original_prompt ) )
        {
            if ( !( stub [[ stub.mc_original_prompt ]]( self ) ) )
                continue;
        }

        success = self mc_do_build_hold( stub, zone );

        if ( success )
        {
            deliverable = self mc_get_deliverable_pieces( zone );
            self mc_deliver_pieces( zone, deliverable );
        }
    }
}

find_bench( bench_name )
{
    return getent( bench_name, "targetname" );
}

mc_swap_buildable_fields( stub1, stub2 )
{
    tbz = stub2.buildablezone;
    stub2.buildablezone = stub1.buildablezone;
    stub2.buildablezone.stub = stub2;
    stub1.buildablezone = tbz;
    stub1.buildablezone.stub = stub1;
    tbs = stub2.buildablestruct;
    stub2.buildablestruct = stub1.buildablestruct;
    stub1.buildablestruct = tbs;
    te = stub2.equipname;
    stub2.equipname = stub1.equipname;
    stub1.equipname = te;
    th = stub2.hint_string;
    stub2.hint_string = stub1.hint_string;
    stub1.hint_string = th;
    ths = stub2.trigger_hintstring;
    stub2.trigger_hintstring = stub1.trigger_hintstring;
    stub1.trigger_hintstring = ths;
    tp = stub2.persistent;
    stub2.persistent = stub1.persistent;
    stub1.persistent = tp;
    tobu = stub2.onbeginuse;
    stub2.onbeginuse = stub1.onbeginuse;
    stub1.onbeginuse = tobu;
    tocu = stub2.oncantuse;
    stub2.oncantuse = stub1.oncantuse;
    stub1.oncantuse = tocu;
    toeu = stub2.onenduse;
    stub2.onenduse = stub1.onenduse;
    stub1.onenduse = toeu;
    tt = stub2.target;
    stub2.target = stub1.target;
    stub1.target = tt;
    ttn = stub2.targetname;
    stub2.targetname = stub1.targetname;
    stub1.targetname = ttn;
    twn = stub2.weaponname;
    stub2.weaponname = stub1.weaponname;
    stub1.weaponname = twn;
    pav = stub2.original_prompt_and_visibility_func;
    stub2.original_prompt_and_visibility_func = stub1.original_prompt_and_visibility_func;
    stub1.original_prompt_and_visibility_func = pav;
    bench1 = undefined;
    bench2 = undefined;
    transfer_pos_as_is = 1;

    if ( isdefined( stub1.model ) && isdefined( stub2.model ) && isdefined( stub1.model.target ) && isdefined( stub2.model.target ) )
    {
        bench1 = find_bench( stub1.model.target );
        bench2 = find_bench( stub2.model.target );

        if ( isdefined( bench1 ) && isdefined( bench2 ) )
        {
            transfer_pos_as_is = 0;
            w2lo1 = bench1 worldtolocalcoords( stub1.model.origin );
            w2la1 = stub1.model.angles - bench1.angles;
            w2lo2 = bench2 worldtolocalcoords( stub2.model.origin );
            w2la2 = stub2.model.angles - bench2.angles;
            stub1.model.origin = bench2 localtoworldcoords( w2lo1 );
            stub1.model.angles = bench2.angles + w2la1;
            stub2.model.origin = bench1 localtoworldcoords( w2lo2 );
            stub2.model.angles = bench1.angles + w2la2;
        }

        tmt = stub2.model.target;
        stub2.model.target = stub1.model.target;
        stub1.model.target = tmt;
    }

    tm = stub2.model;
    stub2.model = stub1.model;
    stub1.model = tm;

    if ( transfer_pos_as_is && isdefined( stub1.model ) && isdefined( stub2.model ) )
    {
        tmo = stub2.model.origin;
        tma = stub2.model.angles;
        stub2.model.origin = stub1.model.origin;
        stub2.model.angles = stub1.model.angles;
        stub1.model.origin = tmo;
        stub1.model.angles = tma;
    }
}

mc_try_deliver_buried()
{
    if ( isdefined( self.mc_last_pickup_time ) && gettime() - self.mc_last_pickup_time < 400 )
        return;

    if ( !self usebuttonpressed() )
        return;

    near_bench_stub = undefined;
    best_dist = MC_BUILD_RADIUS_SQ;

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.table_built ) && stub.table_built )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        s_orig = mc_get_stub_origin( stub );
        if ( isdefined( s_orig ) && mc_in_range( self.origin, s_orig, MC_BUILD_RADIUS_SQ ) )
        {
            dist = distance2dsquared( self.origin, s_orig );
            if ( dist < best_dist )
            {
                best_dist = dist;
                near_bench_stub = stub;
            }
        }
    }

    if ( !isdefined( near_bench_stub ) )
        return;

    target_stub = undefined;

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.table_built ) && stub.table_built )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        zone = stub.buildablezone;
        deliverable = self mc_get_deliverable_pieces( zone );
        can_attempt = false;

        if ( mc_is_gated( zone.buildable_name ) )
            can_attempt = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
        else
            can_attempt = deliverable.size > 0;

        if ( isdefined( self.mc_preferred_buildable ) && self.mc_preferred_buildable != zone.buildable_name )
            can_attempt = false;

        if ( can_attempt )
        {
            target_stub = stub;
            break;
        }
    }

    if ( !isdefined( target_stub ) )
        return;

    if ( near_bench_stub != target_stub )
    {
        mc_swap_buildable_fields( near_bench_stub, target_stub );
    }

    near_bench_stub.bound_to_buildable = near_bench_stub;
    active_stub = near_bench_stub;

    target_b_name = active_stub.buildablezone.buildable_name;

    success = self mc_do_build_hold( active_stub, active_stub.buildablezone );

    if ( success )
    {
        deliverable = self mc_get_deliverable_pieces( active_stub.buildablezone );
        self mc_deliver_pieces( active_stub.buildablezone, deliverable );

        active_stub.table_built = true;
        active_stub.built = true;
        active_stub.bound_to_buildable = undefined;
    }
}

custom_pooledbuildable_stub_for_piece( piece )
{
    if ( !isdefined( piece ) )
        return undefined;

    if ( !isdefined( self.stubs ) )
        return undefined;

    foreach ( stub in level.buildable_stubs )
    {
        if ( isdefined( stub.buildablezone ) && stub.buildablezone buildable_has_piece( piece ) )
        {
            if ( isdefined( stub.bound_to_buildable ) && stub.bound_to_buildable == stub )
                return stub;
        }
    }

    valid_stubs = [];

    foreach ( stub in level.buildable_stubs )
    {
        if ( isdefined( stub.buildablezone ) && stub.buildablezone buildable_has_piece( piece ) )
        {
            valid_stubs[valid_stubs.size] = stub;
        }
    }

    if ( valid_stubs.size > 0 )
    {
        target_idx = 0;
        p_name = piece.piece_name;
        b_name = piece.buildablename;
        
        if ( !isdefined( p_name ) )
            p_name = "";
        if ( !isdefined( b_name ) )
            b_name = "";

        if ( b_name == "turbine" || issubstr( p_name, "turbine" ) || issubstr( p_name, "fan" ) || issubstr( p_name, "panel" ) || issubstr( p_name, "tail" ) || issubstr( p_name, "meter" ) ) target_idx = 0;
        else if ( b_name == "springpad_zm" || issubstr( p_name, "springpad" ) || issubstr( p_name, "flag" ) || issubstr( p_name, "motor" ) || issubstr( p_name, "screen" ) || issubstr( p_name, "spring" ) || issubstr( p_name, "bellows" ) ) target_idx = 1;
        else if ( b_name == "subwoofer_zm" || b_name == "subwoofer" || issubstr( p_name, "subwoofer" ) || issubstr( p_name, "speaker" ) || issubstr( p_name, "turntable" ) || issubstr( p_name, "board" ) || issubstr( p_name, "cabinet" ) ) target_idx = 2;
        else if ( b_name == "headchopper_zm" || issubstr( p_name, "headchopper" ) || issubstr( p_name, "blade" ) || issubstr( p_name, "gear" ) || issubstr( p_name, "helmet" ) || issubstr( p_name, "shaft" ) ) target_idx = 3;

        for ( i = 0; i < valid_stubs.size; i++ )
        {
            idx = (target_idx + i) % valid_stubs.size;
            stub = valid_stubs[idx];

            if ( !( isdefined( stub.built ) && stub.built ) )
            {
                return stub;
            }
        }
        
        return valid_stubs[0];
    }

    return undefined;
}

mc_deliver_pieces( zone, pieces )
{
    for ( i = 0; i < pieces.size; i++ )
    {
        piece = pieces[i];

        if ( isdefined( zone.stub.buildablestruct ) && isdefined( zone.stub.buildablestruct.onuseplantobject ) )
        {
            self player_set_buildable_piece( piece, zone.buildable_slot );
            zone.stub [[ zone.stub.buildablestruct.onuseplantobject ]]( self );
        }

        one_piece = [];
        one_piece[0] = piece;
        self player_build( zone, one_piece );

        key = mc_piece_key( piece );

        if ( isdefined( self.mc_have[key] ) )
        {
            self.mc_have[key] = self.mc_have[key] - 1;

            if ( self.mc_have[key] <= 0 )
                self.mc_have[key] = undefined;
        }
    }
}

mc_do_build_hold( stub, zone )
{
    self endon( "disconnect" );
    self endon( "death" );

    build_time = MC_DEFAULT_BUILD_TIME;

    if ( isdefined( stub.usetime ) )
        build_time = stub.usetime;

    self disable_player_move_states( 1 );
    self increment_is_drinking();
    orgweapon = self getcurrentweapon();
    self giveweapon( "zombie_builder_zm" );
    self switchtoweapon( "zombie_builder_zm" );

    self.mc_buildaudio = spawn( "script_origin", self.origin );
    self.mc_buildaudio playloopsound( "zmb_buildable_loop" );

    self.mc_build_active = 1;
    start_time = gettime();
    self thread mc_build_progress_bar( start_time, build_time );
    self thread mc_build_dust_fx();

    success = true;

    while ( gettime() - start_time < build_time )
    {
        if ( !isdefined( self ) || !self usebuttonpressed() )
        {
            success = false;
            break;
        }

        stub_origin = mc_get_stub_origin( stub );

        if ( !mc_in_range( self.origin, stub_origin, mc_build_radius_sq( zone.buildable_name ) ) )
        {
            success = false;
            break;
        }

        wait 0.05;
    }

    self.mc_build_active = 0;

    if ( isdefined( self.mc_buildaudio ) )
    {
        self.mc_buildaudio delete();
        self.mc_buildaudio = undefined;
    }

    self maps\mp\zombies\_zm_weapons::switch_back_primary_weapon( orgweapon );
    self takeweapon( "zombie_builder_zm" );

    if ( isdefined( self.is_drinking ) && self.is_drinking )
        self decrement_is_drinking();

    self enable_player_move_states();

    return success;
}

mc_build_progress_bar( start_time, build_time )
{
    self endon( "disconnect" );
    self endon( "death" );

    usebar = self createprimaryprogressbar();
    usebartext = self createprimaryprogressbartext();
    usebartext settext( &"ZOMBIE_BUILDING" );

    while ( isdefined( self ) && isdefined( self.mc_build_active ) && self.mc_build_active && gettime() - start_time < build_time )
    {
        progress = ( gettime() - start_time ) / build_time;

        if ( progress < 0 )
            progress = 0;

        if ( progress > 1 )
            progress = 1;

        usebar updatebar( progress );
        wait 0.05;
    }

    usebartext destroyelem();
    usebar destroyelem();
}

mc_build_dust_fx()
{
    self endon( "disconnect" );
    self endon( "death" );

    while ( isdefined( self ) && isdefined( self.mc_build_active ) && self.mc_build_active )
    {
        playfx( level._effect["building_dust"], self getplayercamerapos(), self.angles );
        wait 0.5;
    }
}

mc_progress_text( zone )
{
    built = 0;

    for ( i = 0; i < zone.pieces.size; i++ )
    {
        if ( isdefined( zone.pieces[i].built ) && zone.pieces[i].built )
            built++;
    }

    deliverable = self mc_get_deliverable_pieces( zone );
    have = built + deliverable.size;

    return have + "/" + zone.pieces.size;
}
mc_sort_available_buildables( available )
{
    sorted = [];
    order = [];
    order[0] = "turbine";
    order[1] = "springpad_zm";
    order[2] = "subwoofer_zm";
    order[3] = "headchopper_zm";

    for ( i = 0; i < order.size; i++ )
    {
        for ( j = 0; j < available.size; j++ )
        {
            if ( isdefined( available[j] ) && isdefined( available[j].buildablezone ) )
            {
                if ( available[j].buildablezone.buildable_name == order[i] )
                {
                    is_dup = false;
                    for ( k = 0; k < sorted.size; k++ )
                    {
                        if ( sorted[k].buildablezone.buildable_name == available[j].buildablezone.buildable_name )
                        {
                            is_dup = true;
                            break;
                        }
                    }

                    if ( !is_dup )
                    {
                        sorted[sorted.size] = available[j];
                    }
                }
            }
        }
    }

    for ( j = 0; j < available.size; j++ )
    {
        if ( isdefined( available[j] ) && isdefined( available[j].buildablezone ) )
        {
            is_dup = false;
            for ( k = 0; k < sorted.size; k++ )
            {
                if ( sorted[k].buildablezone.buildable_name == available[j].buildablezone.buildable_name )
                {
                    is_dup = true;
                    break;
                }
            }

            if ( !is_dup )
            {
                sorted[sorted.size] = available[j];
            }
        }
    }

    return sorted;
}

mc_get_available_buildables_at_pos()
{
    available = [];
    map = getdvar( "mapname" );

    if ( map == "zm_buried" )
    {
        near_bench = false;
        foreach ( stub in level.buildable_stubs )
        {
            if ( !isdefined( stub.buildablezone ) || !mc_is_ours( stub.buildablezone.buildable_name ) )
                continue;
            if ( isdefined( stub.table_built ) && stub.table_built )
                continue;
            if ( isdefined( stub.built ) && stub.built )
                continue;

            stub_origin = mc_get_stub_origin( stub );
            if ( isdefined( stub_origin ) && mc_in_range( self.origin, stub_origin, MC_BUILD_RADIUS_SQ ) )
            {
                near_bench = true;
                break;
            }
        }

        if ( near_bench )
        {
            foreach ( stub in level.buildable_stubs )
            {
                if ( !isdefined( stub.buildablezone ) || !isdefined( stub.buildablezone.pieces ) )
                    continue;
                if ( !mc_is_ours( stub.buildablezone.buildable_name ) )
                    continue;
                if ( isdefined( stub.table_built ) && stub.table_built )
                    continue;
                if ( isdefined( stub.built ) && stub.built )
                    continue;

                zone = stub.buildablezone;
                deliverable = self mc_get_deliverable_pieces( zone );
                can_attempt = false;

                if ( mc_is_gated( zone.buildable_name ) )
                    can_attempt = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
                else
                    can_attempt = deliverable.size > 0;

                if ( can_attempt )
                {
                    already_added = false;
                    for ( i = 0; i < available.size; i++ )
                    {
                        if ( available[i].buildablezone.buildable_name == stub.buildablezone.buildable_name )
                        {
                            already_added = true;
                            break;
                        }
                    }

                    if ( !already_added )
                        available[available.size] = stub;
                }
            }
        }
        return mc_sort_available_buildables( available );
    }

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !isdefined( stub.buildablezone.pieces ) )
            continue;

        if ( !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.table_built ) && stub.table_built )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        zone = stub.buildablezone;
        stub_origin = mc_get_stub_origin( stub );

        if ( !mc_in_range( self.origin, stub_origin, mc_build_radius_sq( zone.buildable_name ) ) )
            continue;

        deliverable = self mc_get_deliverable_pieces( zone );
        can_attempt = false;

        if ( mc_is_gated( zone.buildable_name ) )
            can_attempt = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
        else
            can_attempt = deliverable.size > 0;

        if ( can_attempt )
        {
            already_added = false;
            for ( i = 0; i < available.size; i++ )
            {
                if ( available[i].buildablezone.buildable_name == stub.buildablezone.buildable_name )
                {
                    already_added = true;
                    break;
                }
            }

            if ( !already_added )
                available[available.size] = stub;
        }
    }

    return mc_sort_available_buildables( available );
}

mc_is_looking_at_buildable_table()
{
    eye = self geteye();
    forward = anglestoforward( self getplayerangles() );

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;
        if ( isdefined( stub.table_built ) && stub.table_built )
            continue;
        if ( isdefined( stub.built ) && stub.built )
            continue;

        s_orig = mc_get_stub_origin( stub );
        if ( isdefined( s_orig ) && distance2dsquared( self.origin, s_orig ) < MC_BUILD_RADIUS_SQ )
        {
            zdiff = self.origin[2] - s_orig[2];
            if ( zdiff < 0 )
                zdiff = zdiff * -1;
                
            if ( zdiff <= MC_HEIGHT_TOLERANCE )
            {
                dir = vectornormalize( s_orig - eye );
                if ( vectordot( forward, dir ) > 0.35 )
                    return true;
            }
        }
    }
    
    return false;
}

mc_build_selection_loop()
{
    self endon( "disconnect" );

    if ( !( isdefined( level.mc_is_buried ) && level.mc_is_buried ) )
        return;

    while ( true )
    {
        if ( self usebuttonpressed() )
        {
            if ( !isdefined( self.mc_f_was_pressed ) || !self.mc_f_was_pressed )
            {
                self.mc_f_was_pressed = 1;

                if ( !isdefined( self.mc_last_f_press ) )
                    self.mc_last_f_press = 0;

                if ( gettime() - self.mc_last_f_press < 500 )
                {
                    self.mc_last_f_press = 0;
                    
                    if ( self mc_is_looking_at_buildable_table() )
                    {
                        available = self mc_get_available_buildables_at_pos();

                        if ( available.size > 1 )
                        {
                            current_idx = 0;
                            if ( isdefined( self.mc_preferred_buildable ) )
                            {
                                for ( i = 0; i < available.size; i++ )
                                {
                                    if ( available[i].buildablezone.buildable_name == self.mc_preferred_buildable )
                                    {
                                        current_idx = i;
                                        break;
                                    }
                                }
                            }

                            next_idx = current_idx + 1;
                            if ( next_idx >= available.size )
                                next_idx = 0;
                                
                            self.mc_preferred_buildable = available[next_idx].buildablezone.buildable_name;
                            self playlocalsound( "zmb_bgb_notification" );
                            self iprintln( "^2Scavenger: Selected " + mc_display_name( self.mc_preferred_buildable ) + "!" );

                            foreach ( stub in available )
                            {
                                stub mc_custom_prompt( self );
                                if ( isdefined( stub.trigger ) && isdefined( stub.hint_string ) )
                                    stub.trigger sethintstring( stub.hint_string );
                            }
                        }
                        else if ( available.size == 1 )
                        {
                            self playlocalsound( "zmb_bgb_notification" );
                            self iprintln( "^2Scavenger: Selected " + mc_display_name( available[0].buildablezone.buildable_name ) + "!" );
                        }
                        else
                        {
                            self iprintln( "^1Scavenger: No buildables at this table!" );
                        }
                    }
                }
                else
                {
                    self.mc_last_f_press = gettime();
                }
            }
        }
        else
        {
            self.mc_f_was_pressed = 0;
        }

        // Ensure preferred buildable is valid for current location
        if ( self mc_is_looking_at_buildable_table() )
        {
            available = self mc_get_available_buildables_at_pos();
            if ( available.size > 0 )
            {
                if ( !isdefined( self.mc_preferred_buildable ) )
                {
                    self.mc_preferred_buildable = available[0].buildablezone.buildable_name;
                    
                    foreach ( stub in available )
                    {
                        stub mc_custom_prompt( self );
                        if ( isdefined( stub.trigger ) && isdefined( stub.hint_string ) )
                            stub.trigger sethintstring( stub.hint_string );
                    }
                }
            }
        }
        
        wait 0.05;
    }
}

// ===== Die Rise Elevator Key & Elevator Lock system =====
// Checks if player is looking directly at an Elevator Key Callbox / Insert Key prompt
mc_is_looking_at_elevator_callbox()
{
    eye = self geteye();
    forward = anglestoforward( self getplayerangles() );

    // Check buildable stubs for elevator key ONLY
    if ( isdefined( level.buildable_stubs ) )
    {
        foreach ( stub in level.buildable_stubs )
        {
            is_key_stub = false;

            if ( isdefined( stub.equipname ) && ( stub.equipname == "elevator_key" || issubstr( stub.equipname, "key" ) ) )
                is_key_stub = true;

            if ( isdefined( stub.targetname ) && ( stub.targetname == "elevator_key_trigger" || issubstr( stub.targetname, "elevator_key" ) || issubstr( stub.targetname, "key" ) ) )
                is_key_stub = true;

            if ( is_key_stub )
            {
                s_orig = mc_get_stub_origin( stub );
                if ( isdefined( s_orig ) && distance2dsquared( self.origin, s_orig ) < 62500 )
                {
                    dir = vectornormalize( s_orig - eye );
                    if ( vectordot( forward, dir ) > 0.35 )
                        return true;
                }
            }
        }
    }

    // Check use triggers related strictly to elevator KEY callboxes (EXCLUDES perk machines & elevator doors!)
    triggers = getentarray( "trigger_use", "classname" );
    triggers_touch = getentarray( "trigger_use_touch", "classname" );
    all_trigs = arraycombine( triggers, triggers_touch, 0, 0 );

    if ( isdefined( all_trigs ) )
    {
        foreach ( trg in all_trigs )
        {
            if ( !isdefined( trg ) )
                continue;

            // Explicitly EXCLUDE Perk machines and vending triggers!
            if ( isdefined( trg.targetname ) && ( issubstr( trg.targetname, "vending" ) || issubstr( trg.targetname, "perk" ) ) )
                continue;

            if ( isdefined( trg.script_noteworthy ) && ( issubstr( trg.script_noteworthy, "vending" ) || issubstr( trg.script_noteworthy, "perk" ) ) )
                continue;

            is_key_trg = false;

            if ( isdefined( trg.targetname ) && ( trg.targetname == "elevator_key_trigger" || issubstr( trg.targetname, "elevator_key" ) || issubstr( trg.targetname, "key" ) || issubstr( trg.targetname, "callbox" ) ) )
                is_key_trg = true;

            if ( isdefined( trg.script_noteworthy ) && ( trg.script_noteworthy == "elevator_key_trigger" || issubstr( trg.script_noteworthy, "elevator_key" ) || issubstr( trg.script_noteworthy, "key" ) || issubstr( trg.script_noteworthy, "callbox" ) ) )
                is_key_trg = true;

            if ( is_key_trg && distance2dsquared( self.origin, trg.origin ) < 62500 )
            {
                dir = vectornormalize( trg.origin - eye );
                if ( vectordot( forward, dir ) > 0.35 )
                    return true;
            }
        }
    }

    return false;
}

mc_get_master_elevator_key_piece()
{
    if ( isdefined( level.buildable_stubs ) )
    {
        foreach ( stub in level.buildable_stubs )
        {
            if ( isdefined( stub.equipname ) && ( stub.equipname == "elevator_key" || issubstr( stub.equipname, "key" ) ) )
            {
                if ( isdefined( stub.buildablezone ) && isdefined( stub.buildablezone.pieces ) && stub.buildablezone.pieces.size > 0 )
                {
                    p = stub.buildablezone.pieces[0];
                    p.buildablezone = stub.buildablezone;
                    return p;
                }
            }
        }
    }

    return undefined;
}

mc_is_key_piece( p )
{
    if ( !isdefined( p ) )
        return false;

    if ( isdefined( p.piece_name ) && ( p.piece_name == "elevator_key" || issubstr( p.piece_name, "key" ) ) )
        return true;

    if ( isdefined( p.buildable_name ) && ( p.buildable_name == "elevator_key" || issubstr( p.buildable_name, "key" ) ) )
        return true;

    if ( isdefined( p.buildablename ) && ( p.buildablename == "elevator_key" || issubstr( p.buildablename, "key" ) ) )
        return true;

    if ( isdefined( p.modelname ) && ( issubstr( p.modelname, "key" ) || issubstr( p.modelname, "vator" ) ) )
        return true;

    if ( isdefined( p.model ) && ( issubstr( p.model, "key" ) || issubstr( p.model, "vator" ) ) )
        return true;

    if ( isdefined( p.equipname ) && ( p.equipname == "elevator_key" || issubstr( p.equipname, "key" ) ) )
        return true;

    if ( isdefined( p.buildablezone ) )
    {
        if ( isdefined( p.buildablezone.buildable_name ) && ( p.buildablezone.buildable_name == "elevator_key" || issubstr( p.buildablezone.buildable_name, "key" ) ) )
            return true;

        if ( isdefined( p.buildablezone.stub ) && isdefined( p.buildablezone.stub.equipname ) && issubstr( p.buildablezone.stub.equipname, "key" ) )
            return true;
    }

    return false;
}

mc_force_delete_player_key()
{
    // Do NOT alter inventory or destroy pieces while player is drinking a perk bottle
    if ( isdefined( self.is_drinking ) && self.is_drinking )
        return;

    // 1. Destroy via player_destroy_piece
    held_pieces = self player_get_buildable_pieces();

    if ( isdefined( held_pieces ) )
    {
        foreach ( p in held_pieces )
        {
            if ( mc_is_key_piece( p ) )
            {
                if ( !isdefined( p.buildablezone ) )
                {
                    master_kp = mc_get_master_elevator_key_piece();
                    if ( isdefined( master_kp ) && isdefined( master_kp.buildablezone ) )
                        p.buildablezone = master_kp.buildablezone;
                }

                if ( isdefined( p.buildablezone ) )
                    self player_destroy_piece( p );
            }
        }
    }

    // 2. Direct cleanup of self.buildable_pieces array and HUD elements
    if ( isdefined( self.buildable_pieces ) )
    {
        slots_to_clear = [];
        foreach ( slot, piece in self.buildable_pieces )
        {
            if ( mc_is_key_piece( piece ) )
            {
                slots_to_clear[slots_to_clear.size] = slot;
            }
        }

        foreach ( slot in slots_to_clear )
        {
            self.buildable_pieces[slot] = undefined;

            if ( isdefined( self.buildable_hud ) && isdefined( self.buildable_hud[slot] ) )
            {
                self.buildable_hud[slot] destroy();
                self.buildable_hud[slot] = undefined;
            }
        }
    }

    // 3. Clear direct player buildable properties
    if ( isdefined( self.buildable_piece ) && mc_is_key_piece( self.buildable_piece ) )
        self.buildable_piece = undefined;
}

// Unlimited Elevator Key logic: Unlocked ONLY after player picks up a key to begin with!
// Regives key when looking at elevator interact, destroys key when looking away.
mc_infinite_elevator_key_think()
{
    self endon( "disconnect" );

    map = getdvar( "mapname" );
    if ( map != "zm_highrise" )
        return;

    level waittill( "buildables_setup" );

    while ( true )
    {
        if ( isdefined( self.is_drinking ) && self.is_drinking )
        {
            wait 0.05;
            continue;
        }

        held_pieces = self player_get_buildable_pieces();
        has_key = false;

        if ( isdefined( held_pieces ) )
        {
            foreach ( p in held_pieces )
            {
                if ( mc_is_key_piece( p ) )
                {
                    has_key = true;
                    break;
                }
            }
        }

        if ( !has_key && isdefined( self.buildable_pieces ) )
        {
            foreach ( slot, p in self.buildable_pieces )
            {
                if ( mc_is_key_piece( p ) )
                {
                    has_key = true;
                    break;
                }
            }
        }

        // Detect initial key pickup to unlock unlimited key feature and IMMEDIATELY delete key from player on pickup
        if ( has_key && !( isdefined( self.mc_has_unlocked_key ) && self.mc_has_unlocked_key ) )
        {
            self.mc_has_unlocked_key = true;
            self mc_force_delete_player_key();
            has_key = false;
        }

        // ONLY manage key if player has picked up a key at least once in this game
        if ( isdefined( self.mc_has_unlocked_key ) && self.mc_has_unlocked_key )
        {
            looking = self mc_is_looking_at_elevator_callbox();

            if ( looking )
            {
                if ( !has_key )
                {
                    kp = mc_get_master_elevator_key_piece();

                    if ( isdefined( kp ) )
                    {
                        slot = "buildable_slot";
                        if ( isdefined( kp.buildablezone ) && isdefined( kp.buildablezone.buildable_slot ) )
                            slot = kp.buildablezone.buildable_slot;

                        self player_set_buildable_piece( kp, slot );
                    }
                }
            }
            else
            {
                // Delete key from player inventory when NOT looking at elevator interact box
                self mc_force_delete_player_key();
            }
        }

        wait 0.05;
    }
}

// Per-player elevator lock & unlock listener: Hold USE key ('F') for 0.5s on Insert Key buildable prompt
mc_elevator_lock_think_player()
{
    self endon( "disconnect" );
    level endon( "end_game" );

    map = getdvar( "mapname" );
    if ( map != "zm_highrise" )
        return;

    level waittill( "buildables_setup" );

    while ( true )
    {
        if ( isdefined( self.is_drinking ) && self.is_drinking )
        {
            wait 0.08;
            continue;
        }

        if ( self usebuttonpressed() )
        {
            if ( self mc_is_looking_at_elevator_callbox() )
            {
                elev = self mc_get_closest_or_occupied_elevator();

                if ( isdefined( elev ) )
                {
                    hold_time = 0;

                    while ( self usebuttonpressed() && self mc_is_looking_at_elevator_callbox() )
                    {
                        hold_time += 0.05;

                        if ( hold_time >= 0.5 )
                        {
                            is_locked = isdefined( elev.mc_locked ) && elev.mc_locked;

                            if ( !is_locked )
                            {
                                // Verify elevator is currently on player's level (Z height difference <= 150 units)
                                zdiff = self.origin[2] - elev.origin[2];
                                if ( zdiff < 0 )
                                    zdiff = zdiff * -1;

                                if ( zdiff <= 33 )//150
                                {
                                    mc_set_elevator_locked_state( elev, true );

                                    self playlocalsound( "zmb_buildable_piece_add" );
                                    self iprintlnbold( "^1Elevator Position Locked!" );
                                }
                                else
                                {
                                    self playlocalsound( "zmb_no_ammo" );
                                    self iprintlnbold( "^1Elevator must be on your level to lock!" );
                                }
                            }
                            else
                            {
                                // Elevator is already locked: Unlock it!
                                mc_set_elevator_locked_state( elev, false );

                                self playlocalsound( "zmb_buildable_piece_add" );
                                self iprintlnbold( "^2Elevator Position Unlocked!" );
                            }

                            while ( self usebuttonpressed() )
                            {
                                wait 0.05;
                            }
                            break;
                        }

                        wait 0.05;
                    }
                }
            }
        }

        wait 0.05;
    }
}

mc_set_elevator_locked_state( elev, is_locked )
{
    if ( !isdefined( elev ) )
        return;

    elev.mc_locked = is_locked;

    if ( is_locked )
    {
        elev.mc_locked_origin = elev.origin;
        elev thread mc_elevator_lock_think();
    }
    else
    {
        elev.mc_locked_origin = undefined;
    }

    if ( isdefined( level.elevators ) )
    {
        foreach ( struct_e in level.elevators )
        {
            if ( isdefined( struct_e ) )
            {
                if ( ( isdefined( struct_e.body ) && struct_e.body == elev ) || ( struct_e == elev ) )
                {
                    struct_e.mc_locked = is_locked;
                    if ( is_locked )
                        struct_e.mc_locked_origin = elev.origin;
                    else
                        struct_e.mc_locked_origin = undefined;
                }
            }
        }
    }
}

mc_elevator_lock_think()
{
    self endon( "death" );

    if ( isdefined( self.mc_lock_loop_active ) && self.mc_lock_loop_active )
        return;

    self.mc_lock_loop_active = true;

    while ( isdefined( self.mc_locked ) && self.mc_locked )
    {
        if ( isdefined( self.mc_locked_origin ) )
        {
            self moveto( self.mc_locked_origin, 0.1 );
        }
        wait 0.05;
    }

    self.mc_lock_loop_active = false;
}

mc_get_closest_or_occupied_elevator()
{
    elevs = mc_get_all_elevator_ents();

    if ( !isdefined( elevs ) || elevs.size == 0 )
        return undefined;

    closest = undefined;
    best_dist = 62500; // 250 units 2D radius max

    p_orig = self.origin;

    foreach ( e in elevs )
    {
        if ( !isdefined( e ) )
            continue;

        e_orig = e.origin;

        // Match 2D distance squared (X/Y plane) to identify elevator car in the target shaft
        d2 = distance2dsquared( p_orig, e_orig );

        if ( d2 < best_dist )
        {
            best_dist = d2;
            closest = e;
        }
    }

    return closest;
}

mc_get_all_elevator_ents()
{
    elevs = [];

    if ( isdefined( level.elevators ) && level.elevators.size > 0 )
    {
        foreach ( e in level.elevators )
        {
            if ( isdefined( e.body ) )
            {
                elevs[elevs.size] = e.body;
            }
            else
            {
                elevs[elevs.size] = e;
            }
        }
    }

    if ( elevs.size > 0 )
        return elevs;

    models = getentarray( "script_model", "classname" );
    brushmodels = getentarray( "script_brushmodel", "classname" );
    all_ents = [];

    if ( isdefined( models ) )
    {
        foreach ( m in models )
            all_ents[all_ents.size] = m;
    }
    if ( isdefined( brushmodels ) )
    {
        foreach ( b in brushmodels )
            all_ents[all_ents.size] = b;
    }

    foreach ( ent in all_ents )
    {
        if ( !isdefined( ent ) )
            continue;

        is_elev = false;

        if ( isdefined( ent.targetname ) && ( issubstr( ent.targetname, "elevator" ) || issubstr( ent.targetname, "vator" ) ) )
            is_elev = true;

        if ( isdefined( ent.model ) && ( issubstr( ent.model, "elevator" ) || issubstr( ent.model, "vator" ) ) )
            is_elev = true;

        if ( isdefined( ent.script_noteworthy ) && ( issubstr( ent.script_noteworthy, "elevator" ) || issubstr( ent.script_noteworthy, "vator" ) ) )
            is_elev = true;

        if ( is_elev )
        {
            elevs[elevs.size] = ent;
        }
    }

    return elevs;
}
