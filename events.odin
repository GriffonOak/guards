package guards

// This is a good file. It knows exactly what it is trying to do and does it extremely well.

import rl "vendor:raylib"

import "core:fmt"
import "core:reflect"
import "core:strings"
import "core:log"



Space_Clicked_Event :: struct {
    space: IVec2
}

Card_Clicked_Event :: struct {
    element: ^UI_Element
}

Confirm_Event :: struct {}

Cancel_Event :: struct {}

Begin_Card_Selection_Event :: struct {}

Begin_Resolution_Event :: struct {}

Begin_Next_Action_Event :: struct {}

Resolve_Current_Action_Event :: struct {
    jump_index: Maybe(int)
}

End_Resolution_Event :: struct {}

Resolutions_Completed_Event :: struct {}

Begin_Minion_Battle_Event :: struct {}

Begin_Minion_Removal_Event :: struct {
    team: Team
}

End_Minion_Battle_Event :: struct {}

Begin_Wave_Push_Event :: struct {
    pushing_team: Team
}

End_Wave_Push_Event :: struct {}

Retrieve_Cards_Event :: struct {}

Begin_Upgrading_Event :: struct {}

End_Upgrading_Event :: struct {}


Game_Over_Event :: struct {
    winning_team: Team
}


Event :: union {
    Space_Clicked_Event,
    Card_Clicked_Event,
    Confirm_Event,
    Cancel_Event,

    Begin_Card_Selection_Event,

    Begin_Resolution_Event,
    Begin_Next_Action_Event,
    Resolve_Current_Action_Event,
    End_Resolution_Event,

    Resolutions_Completed_Event,

    Begin_Minion_Battle_Event,
    Begin_Minion_Removal_Event,
    End_Minion_Battle_Event,

    Begin_Wave_Push_Event,
    End_Wave_Push_Event,

    Retrieve_Cards_Event,

    Begin_Upgrading_Event,
    End_Upgrading_Event,

    Game_Over_Event,
}



event_queue: [dynamic]Event
