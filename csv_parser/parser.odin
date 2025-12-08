package parser

import "core:os"
import "core:strings"
import "core:fmt"
import "core:strconv"


hero_name :: "Garrus"

NUM_Cards :: 17
cards: [NUM_Cards]Card

Card :: struct {
    name: string,

    color: string,
    tier: int,
    alternate: bool,
    
    initiative: int,
    attack_value: int,
    defense_value: int,
    movement_value: int,

    primary: string,
    primary_sign: string,
    reach: string,
    reach_sign: string,
    item: string,
    text: string,
}

main :: proc() {
    input_filename := fmt.tprintf("csv_parser/input/Cards - %v.csv", hero_name)
    // fmt.println(input_filename)
    in_file, ok := os.read_entire_file(input_filename)
    assert(ok)
    lines := strings.split(string(in_file), "\r\n")

    ult_line := lines[22]
    ult_line_tokens := strings.split(ult_line, "\"")
    if len(ult_line_tokens) == 1 {
        ult_line_tokens = strings.split(ult_line, ",")
    }
    ult_text := ult_line_tokens[1]
    

    card_lines := lines[4:][:NUM_Cards]

    for line in card_lines {
        card: Card
        tokens := strings.split(line, ",")

        card.name = tokens[0]
        card.color =  strings.to_ada_case(tokens[1])
        card.tier, _ = strconv.parse_int(tokens[2])
        card.alternate, _ = strconv.parse_bool(tokens[3])
        card.initiative, _ = strconv.parse_int(tokens[4])
        card.attack_value, _ = strconv.parse_int(tokens[5])
        card.defense_value, _ =  strconv.parse_int(tokens[6])
        card.movement_value, _ =  strconv.parse_int(tokens[7])

        card.primary = strings.to_ada_case(tokens[8])
        card.primary_sign = strings.to_ada_case(tokens[9])
        card.reach = tokens[10]
        card.reach_sign = strings.to_ada_case(tokens[11])
        card.item = strings.to_ada_case(tokens[12])


        text_slice := tokens[13:]
        text := strings.join(text_slice, ",")
        if text[0] == '\"' {
            text = text[1:len(text)-1]
        }
        card.text = text
        // card.text, _ = strings.replace(text, "\\n", "\n", -1)

        index: int

        color_offset :: proc(color: string) -> int {
            if color == "Red" do return 0
            if color == "Green" do return 1
            if color == "Blue" do return 2
            assert(false)
            return -999
        }

        switch card.tier {
        case 0:
            index = 0 if card.color == "Gold" else 1
        case 1:
            index = 2 + color_offset(card.color)
        case 2..=3:
            index = 5 + 6 * (card.tier - 2) + 2 * color_offset(card.color) + (1 if card.alternate else 0)
        }

        cards[index] = card

    }

    // for card in cards {
    //     fmt.printfln("%#v", card)
    // }
    builder := strings.builder_make()


    fmt.sbprintfln(&builder, "package guards")
    fmt.sbprintfln(&builder, "")
    fmt.sbprintfln(&builder, "/// %v", hero_name)
    fmt.sbprintfln(&builder, "")
    fmt.sbprintfln(&builder, "//  Ult: %v", ult_text)
    fmt.sbprintfln(&builder, "")
    fmt.sbprintfln(&builder, "%v_cards := []Card_Data {{", strings.to_lower(hero_name))
    for card in cards {
        fmt.sbprintfln(&builder, "\tCard_Data {{ name = \"%v\",", card.name)
        fmt.sbprintfln(&builder, "\t\tcolor\t\t\t= .%v,", card.color)
        if card.tier > 0 do fmt.sbprintfln(&builder, "\t\ttier\t\t\t= %v,", card.tier)
        if card.alternate do fmt.sbprintfln(&builder, "\t\talternate\t\t= true,")
        
        fmt.sbprintf(&builder, "\t\tvalues\t\t\t= #partial{{")
        fmt.sbprintf(&builder, ".Initiative = %v", card.initiative)
        fmt.sbprintf(&builder, ", .Defense = %v", card.defense_value)
        if card.attack_value > 0 do fmt.sbprintf(&builder, ", .Attack = %v", card.attack_value)
        if card.movement_value > 0 do fmt.sbprintf(&builder, ", .Movement = %v", card.movement_value)
        if card.reach != "" {
            if strings.starts_with(card.reach, "Range(") {
                fmt.sbprintf(&builder, ", .Range = %v", card.reach[6:len(card.reach)-1])
            }
            if strings.starts_with(card.reach, "Radius(") {
                fmt.sbprintf(&builder, ", .Radius = %v", card.reach[7:len(card.reach)-1])
            }
        }
        fmt.sbprintfln(&builder, "}},")
        fmt.sbprintfln(&builder, "\t\tprimary\t\t\t= .%v,", card.primary)
        if card.primary_sign != "" do fmt.sbprintfln(&builder, "\t\tprimary_sign\t= .%v,", card.primary_sign)
        if card.reach_sign != "" do fmt.sbprintfln(&builder, "\t\treach_sign\t= .%v,", card.reach_sign)
        if card.item != "" do fmt.sbprintfln(&builder, "\t\titem\t\t\t= .%v,", card.item)
        fmt.sbprintfln(&builder, "\t\ttext\t\t\t= \"%v\",", card.text)
        fmt.sbprintfln(&builder, "\t\tprimary_effect\t= []Action {{}},")



        fmt.sbprintfln(&builder, "\t}},")
    }
    fmt.sbprintfln(&builder, "}}")

    out_string := strings.expand_tabs(strings.to_string(builder), 4)


    outfile_name := fmt.tprintf("csv_parser/output/hero_%v.odin", strings.to_lower(hero_name))
    os.remove(outfile_name)
    outfile, err := os.open(outfile_name, os.O_WRONLY | os.O_CREATE)
    assert(err == nil)
    fmt.fprint(outfile, out_string)
    os.close(outfile)
}