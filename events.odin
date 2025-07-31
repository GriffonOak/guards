package guards

Space_Clicked :: struct {
    space: IVec2
}

Event :: union {
    Space_Clicked
}

event_queue: [dynamic]Event

resolve_event :: proc(event: Event) {

}