package guards


import "core:log"
import "base:intrinsics"

Action_Value_Label :: enum {
    None,
    Attack_Target,
    Movement_Target,
    Place_Target,

    Chosen_Quantity,

    Choice_Taken,
    Repeat_Count,

    Chosen_Minion_Type,

    Arien_Dueling_Partner,
    Swift_Farm_Defeat_Count,
    Brogan_Prevent_Next_Minion_Removal,
    Bain_Color_Guess,
    Bain_Color_Answer,
}

Action_Value_Variant :: union {
    int,
    bool,
    Target,
    Path,
    Card_ID,
    Space_Flag,
}

Action_Value :: struct {
    action_index: Action_Index,
    action_count: int,
    label: Action_Value_Label,
    variant: Action_Value_Variant,
}


add_action_value :: proc(
    gs: ^Game_State,
    value: Action_Value_Variant,
    index: Action_Index = {},
    label: Action_Value_Label = .None,
    global: bool = false,
) {
    // depth := len(gs.interrupt_stack)
    index := index
    if index == {} {
        index = get_my_player(gs).hero.current_action_index
    }
    action_value := Action_Value {
        action_index = index,
        action_count = gs.action_count,
        // depth = depth,
        label = label,
        variant = value,
    }
    if !global {
        append(&gs.action_memory, action_value)
    } else {
        log.assert(label != .None, "Cannot add a non-labelled global variable!!!")
        broadcast_game_event(gs, Add_Global_Variable_Event{action_value})
    }
}

get_top_memory_slice :: proc(
    gs: ^Game_State, $T: typeid, index: Action_Index = {}, count: int = -1
) -> []Action_Value where intrinsics.type_is_variant_of(Action_Value_Variant, T) {
    end_index := len(gs.action_memory) - 1
    for end_index >= 0 {
        if _, ok := gs.action_memory[end_index].variant.(T); ok &&
            (index == {} || gs.action_memory[end_index].action_index == index) &&
            (count == -1 || count == gs.action_memory[end_index].action_count) {
            break
        }
        end_index -= 1
    }

    start_index := end_index
    for start_index >= 0 {
        if _, ok := gs.action_memory[start_index].variant.(T); !ok ||
            (index != {} && gs.action_memory[start_index].action_index != index) ||
            (count != -1 && count != gs.action_memory[end_index].action_count) {
            break
        }
        start_index -= 1 
    }
    start_index += 1
    end_index += 1
    if end_index > len(gs.action_memory) || start_index >= len(gs.action_memory) do return {}
    return gs.action_memory[start_index:end_index]
}

clear_top_memory_slice :: proc(gs: ^Game_State) {
    top_index := get_my_player(gs).hero.current_action_index 

    start_index := len(gs.action_memory) - 1
    for start_index >= 0 && gs.action_memory[start_index].action_index == top_index && gs.action_memory[start_index].action_count == gs.action_count {
        start_index -= 1 
    }
    start_index += 1
    // if start_index >= len(gs.action_memory) do return
    resize(&gs.action_memory, len(gs.action_memory) - start_index)
    // return gs.action_memory[start_index:end_index]
}

// You need to be sure this exists otherwise it will crash
get_top_action_value_of_type :: proc(
    gs: ^Game_State, $T: typeid, index: Action_Index = {}, count: int = -1, label: Action_Value_Label = .None
) -> ^T where intrinsics.type_is_variant_of(Action_Value_Variant, T) {
    value, _, ok := try_get_top_action_value_of_type(gs, T, index, count, label)
    log.assert(ok, "Invalid type assertion for action value!")
    return value
}

try_get_top_action_value_of_type :: proc(
    gs: ^Game_State, $T: typeid, index: Action_Index = {}, count: int = -1, label: Action_Value_Label = .None
) -> (^T, Action_Index, bool) where intrinsics.type_is_variant_of(Action_Value_Variant, T) {
    #reverse for &value in gs.action_memory {
        if label != .None && value.label != label do continue
        if index != {} && value.action_index != index do continue
        if count != -1 && value.action_count != count do continue
        typed_value, ok := &value.variant.(T)
        if ok do return typed_value, value.action_index, true
    }
    return nil, {}, false
}

get_top_global_variable_by_label :: proc(gs: ^Game_State, label: Action_Value_Label) -> ^Action_Value {
    #reverse for &value in gs.global_memory {
        if value.label == label do return &value
    }
    return nil
}
