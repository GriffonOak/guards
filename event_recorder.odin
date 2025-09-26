package guards

import "core:os"
import "core:fmt"
import "core:time"


recording_events: bool
record_file: os.Handle
previous_event: Event

begin_recording_events :: proc() {
    now := time.now()

    time_buf: [time.MIN_HMS_LEN]u8
    date_buf: [time.MIN_YYYY_DATE_LEN]u8

    time_string := time.to_string_hms(now, time_buf[:])
    date_string := time.to_string_yyyy_mm_dd(now, date_buf[:])
    for &r in time_buf do if r == ':' do r = '-'

    filename := fmt.tprintf("records/%v__%v.txt", date_string, time_string)

    handle, err := os.open(filename, os.O_CREATE | os.O_RDWR)

    if err == nil {
        record_file = handle
        recording_events = true

        fmt.fprintfln(record_file, "event_log := []Event {{")
        fmt.fprintfln(record_file, "    %w,", Host_Game_Chosen_Event{})
    }
}

record_events :: proc(events: []Event) {
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

stop_recording_events :: proc() {
    if previous_event != nil do fmt.fprintfln(record_file, "    %w,", previous_event)
    fmt.fprintfln(record_file, "}}")
    os.close(record_file)
}