// abandon hope all ye who enter here

package guards

import "core:fmt"
import "core:log"
import "core:slice"
import "core:reflect"

import "core:mem"
import "core:net"
import "core:thread"
import "core:sync"

import "core:testing"

LOOPBACK_ADDRESS :: "127.0.0.1"
MY_ADDRESS :: LOOPBACK_ADDRESS // "25.2.114.107"

GUARDS_PORT :: 8081


Set_Client_Player_ID :: struct {
    player_id: Player_ID,
}

Network_Event :: union {
    Set_Client_Player_ID,
    Event,
}

Network_Packet :: struct {
    sender: Player_ID,
    event: Network_Event,
}

broadcast_game_event :: proc(gs: ^Game_State, event: Event) {

    broadcast_network_event(gs, event)
    append(&gs.event_queue, event)

}

broadcast_network_event :: proc(gs: ^Game_State, net_event: Network_Event) {
    packet := Network_Packet {
        gs.my_player_id,
        net_event,
    }

    if gs.is_host {
        for player, player_id in gs.players {
            if player_id != 0 {
                send_network_packet_socket(player.socket, packet)
            }
        }
    } else {
        send_network_packet_socket(gs.host_socket, packet)
    }
}


send_network_packet_socket :: proc(socket: net.TCP_Socket, net_event: Network_Packet) {
    net_event := net_event
    to_send := mem.ptr_to_bytes(&net_event)

    net.send_tcp(socket, to_send)
}



join_local_game :: proc(gs: ^Game_State) -> bool {

    gs.is_host = false
    local_address, _ := net.parse_ip4_address(MY_ADDRESS)

	socket, err := net.dial_tcp_from_address_and_port(local_address, GUARDS_PORT)
	if err != nil {
		fmt.println("Failed to connect to server")
		return false
	}

    gs.host_socket = socket
    add_socket_listener(gs, socket)
    return true
}

@(test)
test_host_local_game :: proc(t: ^testing.T) {
    gs: Game_State

    out := begin_hosting_local_game(&gs)

    testing.expect(t, out, "Failed to begin hosting!")

    testing.expect(t, gs.is_host, "Failed to become host!")
    testing.expect(t, len(gs.players) == 1, "There is not exactly 1 player!")
    testing.expect(t, gs.my_player_id == 0, "Host player ID is not 0!")
    player := gs.players[0]
    testing.expect(t, player.id == 0, "Player 0 does not have ID 0!")
    testing.expect(t, player.is_team_captain == true, "Host player is not the team captain!")
}

// The host always has player ID 0
begin_hosting_local_game :: proc(gs: ^Game_State) -> bool {

    gs.is_host = true
    local_addr, ok := net.parse_ip4_address("0.0.0.0")

	if !ok {
		log.error("Failed to parse IP address")
		return false
	}
	endpoint := net.Endpoint {
		address = local_addr,
		port    = GUARDS_PORT,
	}
	sock, err := net.listen_tcp(endpoint)
when !ODIN_TEST {  // Apparently the address is in use during testing (?)
	if err != nil {
		log.error("Failed to listen on TCP:", err)
		return false
	}
}
	log.debug("Listening on TCP: %s", net.endpoint_to_string(endpoint))

    gs.my_player_id = 0
    clear(&gs.players)
    me := Player {
        id = 0,
        hero = Hero {
            id = .XARGATHA,
        },
        team = .RED,
        is_team_captain = true,
    }
    fmt.bprintf(me._username_buf[:], "P%v", 0)

    add_or_update_player(gs, me)

    thread.create_and_start_with_poly_data2(gs, sock, _thread_host_wait_for_clients)
    return true
}

_thread_host_wait_for_clients :: proc(gs: ^Game_State, sock: net.TCP_Socket) {
    // Host only!

    for {
		client, _, err_accept := net.accept_tcp(sock)
		if err_accept != nil {
			log.error("Failed to accept TCP connection")
		} else {
            log.debug("Connected with client!", client)
            add_socket_listener(gs, client)

            if gs.stage != .IN_LOBBY do return

            client_player_id := len(gs.players)

            // Right now we just completely decide the fate of the client but realistically they should get to decide their own team and stuff
            client_player := Player {
                id = client_player_id,
                stage = .SELECTING,
                hero = Hero {
                    id = .XARGATHA,
                },
                team = .BLUE,
                is_team_captain = client_player_id == 1,
                socket = client,
            }
            fmt.bprintf(client_player._username_buf[:], "P%v", client_player_id)
            add_or_update_player(gs, client_player)

            for player, player_id in gs.players {
                if player_id != 0 {
                    // Update existing player that new player has joined
                    send_network_packet_socket(player.socket, {0, Event(Update_Player_Data_Event{client_player})})
                }
                // Inform joining player of existing player
                send_network_packet_socket(client, {0, Event(Update_Player_Data_Event{player})})
            }

            send_network_packet_socket(client, {0, Set_Client_Player_ID{client_player_id}})

            // for player in gs.players {
            //     // update existing players that new player has joined
            //     // At some point :P
            // }
        }
	}
	net.close(sock)
	log.debug("Closed socket")
}

_thread_listen_socket :: proc(gs: ^Game_State, socket: net.TCP_Socket) {
    buf: [20 * size_of(Network_Packet)]byte
    for {  // Probably this should end at some point
        bytes_read, err := net.recv_tcp(socket, buf[:])
        if err != nil {
            log.errorf("Network receive error!")
        }
        if bytes_read >= size_of(Network_Packet) {
            packets := slice.reinterpret([]Network_Packet, buf[:bytes_read])
            sync.mutex_lock(&gs.net_queue_mutex)
            for packet in packets {
                append(&gs.network_queue, packet)
            }
            sync.mutex_unlock(&gs.net_queue_mutex)
        }
    }
}

add_socket_listener :: proc(gs: ^Game_State, socket: net.TCP_Socket) {
    thread.create_and_start_with_poly_data2(gs, socket, _thread_listen_socket)
}

process_network_packets :: proc(gs: ^Game_State) {

    sync.mutex_lock(&gs.net_queue_mutex) 
    defer sync.mutex_unlock(&gs.net_queue_mutex)

    for packet in gs.network_queue {
        log.infof("NET: %v", reflect.union_variant_typeid(packet.event))

        // broadcast packet to everyone
        if gs.is_host && packet.sender != 0 {
            for player, player_id in gs.players {
                if player_id != 0 && player_id != packet.sender {
                    send_network_packet_socket(player.socket, packet)
                }
            }
        }

        switch event in packet.event {
        case Set_Client_Player_ID:
            if !gs.is_host {
                gs.my_player_id = event.player_id
            }

        case Event:
            log.infof("NET: %v", reflect.union_variant_typeid(event))
            append(&gs.event_queue, event)
        }
    }

    clear(&gs.network_queue)
}