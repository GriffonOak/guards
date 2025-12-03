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
    when !ODIN_TEST {
        net_event := net_event
        to_send := mem.ptr_to_bytes(&net_event)
    
        bytes_sent := 0
        for bytes_sent < size_of(Network_Packet) {
            new_bytes_sent, err := net.send_tcp(socket, to_send[bytes_sent:])
            if err != .None {
                log.errorf("Network send error: %v", err)
            }
            bytes_sent += new_bytes_sent
        }
    }
}


Parse_Error :: struct {}
Dial_Error :: struct {}

Join_Game_Error :: union {
    Parse_Error,
    Dial_Error,
}


join_game :: proc(gs: ^Game_State, ip: string = "") -> Join_Game_Error {

    gs.is_host = false
    ip := ip
    if ip == "" do ip = LOOPBACK_ADDRESS
    local_address, ok := net.parse_ip4_address(ip)
    if !ok do return Parse_Error{}

	socket, err := net.dial_tcp_from_address_and_port(local_address, GUARDS_PORT)
	if err != nil {
		return Dial_Error{}
	}

    gs.host_socket = socket
    add_socket_listener(gs, socket)
    return nil
}

@(test)
test_host_local_game :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)
    
    gs: Game_State
    out := begin_hosting_local_game(&gs)

    testing.expect(t, out, "Failed to begin hosting!")

    testing.expect(t, gs.is_host, "Failed to become host!")
    testing.expect(t, len(gs.players) == 1, "There is not exactly 1 player!")
    testing.expect(t, gs.my_player_id == 0, "Host player ID is not 0!")
    player := gs.players[0]
    testing.expect(t, player.id == 0, "Player 0 does not have ID 0!")
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
            id = .Xargatha,
        },
        team = .Red,
    }
    fmt.bprintf(me._username_buf[:], "P%v", 0)

    add_or_update_player(gs, me)

    thread.create_and_start_with_poly_data2(gs, sock, _thread_host_wait_for_clients)
    return true
}

_thread_host_wait_for_clients :: proc(gs: ^Game_State, sock: net.TCP_Socket) {
    // Host only!

    for {
		client_socket, _, err_accept := net.accept_tcp(sock)
		if err_accept != nil {
			log.error("Failed to accept TCP connection")
		} else {
            log.debug("Connected with client!", client_socket)
            add_socket_listener(gs, client_socket)

            if gs.screen != .Lobby do return

            team_counts: [Team]int
            for player in gs.players {
                team_counts[player.team] += 1
            }
            first_available_hero: Hero_ID
            search_heroes: for hero in Hero_ID {
                for player in gs.players {
                    if player.hero.id == hero do continue search_heroes
                }
                first_available_hero = hero
                break
            }


            // Right now we just completely decide the fate of the client but realistically they should get to decide their own team and stuff
            client_player := Player {
                id = len(gs.players),
                stage = .Selecting,
                hero = Hero {
                    id = first_available_hero,
                },
                team = .Red if team_counts[.Red] <= team_counts [.Blue] else .Blue,
                socket = client_socket,
            }
            fmt.bprintf(client_player._username_buf[:], "P%v", client_player.id)
            append(&gs.players, client_player)

            broadcast_game_event(gs, Update_Player_Data_Event{client_player.base})

            for player in gs.players {
                // Inform joining player of existing players
                send_network_packet_socket(client_socket, {0, Event(Update_Player_Data_Event{player.base})})
            }

            send_network_packet_socket(client_socket, {0, Set_Client_Player_ID{client_player.id}})
            send_network_packet_socket(client_socket, {0, Event(Set_Preview_Mode_Event{gs.preview_mode})})
            send_network_packet_socket(client_socket, {0, Event(Set_Game_Length_Event{gs.game_length})})

        }
	}
	net.close(sock)
	log.debug("Closed socket")
}

_thread_listen_socket :: proc(gs: ^Game_State, socket: net.TCP_Socket) {
    buf: [1 * size_of(Network_Packet)]byte
    bytes_read := 0
    for {  // Probably this should end at some point
        new_bytes_read, err := net.recv_tcp(socket, buf[bytes_read:])
        if err != nil {
            log.errorf("Network receive error: %v", err)
            bytes_read = 0
            continue
        }
        bytes_read += new_bytes_read
        if bytes_read >= size_of(Network_Packet) {
            packets := slice.reinterpret([]Network_Packet, buf[:])
            sync.mutex_lock(&gs.net_queue_mutex)
            for packet in packets {
                append(&gs.network_queue, packet)
            }
            sync.mutex_unlock(&gs.net_queue_mutex)
            bytes_read = 0
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
            append(&gs.event_queue, Enter_Lobby_Event{})

        case Event:
            log.infof("NET: %v", reflect.union_variant_typeid(event))
            append(&gs.event_queue, event)
        }
    }

    clear(&gs.network_queue)
}