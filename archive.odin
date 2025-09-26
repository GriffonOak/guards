package guards


// Generating zone indices

// zone_indices: [Region_ID][dynamic]Target

// assign_region_symmetric :: proc(gs: ^Game_State, target: Target, region_id: Region_ID) {
//     gs.board[target.x][target.y].region_id = region_id
//     append(&zone_indices[region_id], target)
//     other_index := Target{GRID_WIDTH, GRID_HEIGHT} - target - 1
//     other_region := Region_ID(len(Region_ID) - int(region_id))
//     gs.board[other_index.x][other_index.y].region_id = other_region
//     append(&zone_indices[other_region], other_index)
// }

// setup_regions :: proc(gs: ^Game_State) {
//     // Bases
//     for x_idx in 1..=4 {
//         for y_idx in 6..=17 {
//             if .Terrain in gs.board[x_idx][y_idx].flags do continue
//             if y_idx <= 14-x_idx {
//                 assign_region_symmetric(gs, Target{i8(x_idx), i8(y_idx)}, .Red_Throne)
//             } else {
//                 assign_region_symmetric(gs, Target{i8(x_idx), i8(y_idx)}, .Red_Jungle)
//             }
//         }
//     }

//     for x_idx in 5..=8 {
//         for y_idx in 3..=17 {
//             if .Terrain in gs.board[x_idx][y_idx].flags do continue
//             if x_idx <= 6 && y_idx >= 16 {
//                 assign_region_symmetric(gs, Target{i8(x_idx), i8(y_idx)}, .Red_Jungle)
//             } else if y_idx <= 16 - x_idx {
//                 assign_region_symmetric(gs, Target{i8(x_idx), i8(y_idx)}, .Red_Beach)
//             }
//         }
//     }

//     for x_idx in 9..=12 {
//         for y_idx in 1..=15-x_idx {
//             if .Terrain in gs.board[x_idx][y_idx].flags do continue
//             assign_region_symmetric(gs, Target{i8(x_idx), i8(y_idx)}, .Red_Beach)
//         }
//     }

//     for x_idx in 5..=14 {
//         for y_idx in 16-x_idx..=19-x_idx {
//             if .Terrain in gs.board[x_idx][y_idx].flags || gs.board[x_idx][y_idx].region_id != .None do continue
//             assign_region_symmetric(gs, Target{i8(x_idx), i8(y_idx)}, .Centre)
//         }
//     }
// }

// Writing them out

// setup_regions(gs)

// handle, err := os.open("indices.txt", os.O_CREATE | os.O_RDWR)
// if err == nil {

//     fmt.fprintfln(handle, "%#w", zone_indices)
//     os.close(handle)
// }