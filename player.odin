package guards

import "core:fmt"
import "core:net"
import "core:reflect"
import "core:log"

_ :: fmt
_ :: reflect

Player_Stage :: enum {
    None,
    Selecting,
    Confirmed,
    Resolving,
    Resolved,
    Upgrading,
    Upgraded,

    Interrupting,
    Interrupted,
}

Hero_ID :: enum {
    Xargatha,
    Dodger,
    Swift,
    Brogan,
    Tigerclaw,
    Wasp,
    Arien,
    Sabina,
    Garrus,
}

number_names := [?]string {
    "0", 
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
}

hero_cards: [Hero_ID][]Card_Data

Marker :: enum {
    Tigerclaw_Weak_Poison,
    Tigerclaw_Strong_Poison,
}

Marker_Set :: bit_set[Marker]

Hero :: struct {
    id: Hero_ID,
    location: Target,
    cards: [Card_Color]Card,

    coins: int,
    level: int,
    dead: bool,
    items: [10]Card_ID,  // lol
    item_count: int,
    markers: Marker_Set,
    remaining_upgrades: int,

    current_action_index: Action_Index,
}

Player_ID :: int

// For sending over the network
Player_Base :: struct {
    id: Player_ID,
    _username_buf: [40]u8,
    team: Team,
    hero: Hero,
}

Player :: struct {
    using base: Player_Base,

    socket: net.TCP_Socket,  // For host use only
    stage: Player_Stage,
}

@(private="file")
TEXT_PADDING :: 6



player_offset :: proc(gs: ^Game_State, player_id: Player_ID) -> int {
    if player_id > gs.my_player_id do return player_id - 1
    return player_id
}

count_hero_items :: proc(gs: ^Game_State, hero: Hero, kind: Card_Value_Kind) -> (out: int) {
    for item_index in 0..<hero.item_count {
        card_id := hero.items[item_index]
        card_data, ok := get_card_data_by_id(card_id)
        log.assert(ok, "Invalid item!")
        if card_data.item == kind do out += 1
    }
    return out
}

add_or_update_player :: proc(gs: ^Game_State, player_base: Player_Base) {

    // Setup player
    if player_base.id >= len(gs.players) {
        resize(&gs.players, player_base.id + 1)
    }
    gs.players[player_base.id].base = player_base
}

get_username :: proc(gs: ^Game_State, player_id: Player_ID) -> cstring {
    return cstring(raw_data(gs.players[player_id]._username_buf[:]))
}

get_player_by_id :: proc(gs: ^Game_State, player_id: Player_ID) -> ^Player {
    if player_id >= len(gs.players) {
        return nil
    }
    return &gs.players[player_id]
}

get_my_player :: proc(gs: ^Game_State) -> ^Player {
    return get_player_by_id(gs, gs.my_player_id)
}