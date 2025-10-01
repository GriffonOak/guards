package guards

import "core:os"
import "core:fmt"


recording_events: bool
previous_event: Event

begin_recording_events :: proc(record_file: os.Handle) {
    recording_events = true
    fmt.fprintfln(record_file, "event_log := []Event {{")

}

record_events :: proc(record_file: os.Handle, events: []Event) {
    for event in events {
        defer previous_event = event
        if _, ok := previous_event.(Space_Hovered_Event); ok {
            if _, ok2 := event.(Space_Hovered_Event); ok2 {
                continue
            }
        }
        if previous_event == nil do continue
        fmt.fprintfln(record_file, "    %w,", previous_event)
    }
}

stop_recording_events :: proc(record_file: os.Handle) {
    if previous_event != nil do fmt.fprintfln(record_file, "    %w,", previous_event)
    fmt.fprintfln(record_file, "}}")
    os.close(record_file)
}