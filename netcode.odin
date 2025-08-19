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

LOOPBACK_ADDRESS :: "127.0.0.1"

GUARDS_PORT :: 8081


Set_Client_Player_ID :: struct {
    player_id: Player_ID,
}

Update_Player_Data :: struct {
    player: Player,
}

Network_Event :: union {
    Set_Client_Player_ID,
    Update_Player_Data,
    Event,
}

Network_Packet :: struct {
    sender: Player_ID,
    event: Network_Event,
}



is_host: bool

host_socket: net.TCP_Socket

net_queue_mutex: sync.Mutex

network_queue: [dynamic]Network_Packet


broadcast_network_event :: proc(net_event: Network_Event) {
    packet := Network_Packet {
        my_player_id,
        net_event,
    }

    if is_host {
        for player_id, player in game_state.players {
            if player_id != 0 {
                send_network_packet_socket(player.socket, packet)
            }
        }
    } else {
        send_network_packet_socket(host_socket, packet)
    }
}


send_network_packet_socket :: proc(socket: net.TCP_Socket, net_event: Network_Packet) {
    net_event := net_event
    to_send := mem.ptr_to_bytes(&net_event)

    net.send_tcp(socket, to_send)
}



join_local_game :: proc() -> bool {

    is_host = false
    local_address, ok := net.parse_ip4_address(LOOPBACK_ADDRESS)

	socket, err := net.dial_tcp_from_address_and_port(local_address, GUARDS_PORT)
	if err != nil {
		fmt.println("Failed to connect to server")
		return false
	}

    host_socket = socket
    add_socket_listener(socket)
    return true
}


// The host always has player ID 0
begin_hosting_local_game :: proc() -> bool {

    is_host = true
    local_addr, ok := net.parse_ip4_address(LOOPBACK_ADDRESS)

	if !ok {
		log.error("Failed to parse IP address")
		return false
	}
	endpoint := net.Endpoint {
		address = local_addr,
		port    = GUARDS_PORT,
	}
	sock, err := net.listen_tcp(endpoint)
	if err != nil {
		log.error("Failed to listen on TCP")
		return false
	}
	log.debug("Listening on TCP: %s", net.endpoint_to_string(endpoint))

    my_player_id = 0
    clear(&game_state.players)
    game_state.players[my_player_id] = Player {
        hero = Hero {
            id = .XARGATHA
        },
        team = .RED,
        is_team_captain = true,
    }

    thread.create_and_start_with_poly_data(sock, _thread_host_wait_for_clients)
    return true
}

_thread_host_wait_for_clients :: proc(sock: net.TCP_Socket) {
    // Host only!

    for {
		client, _, err_accept := net.accept_tcp(sock)
		if err_accept != nil {
			log.error("Failed to accept TCP connection")
		} else {
            log.debug("Connected with client!", client)
            add_socket_listener(client)

            if game_state.stage != .IN_LOBBY do return

            client_player_id := len(game_state.players)

            // Right now we just completely decide the fate of the client but realistically they should get to decide their own team and stuff
            client_player := Player {
                id = client_player_id,
                stage = .SELECTING,
                hero = Hero {
                    id = .XARGATHA
                },
                team = .BLUE,
                is_team_captain = true,
                socket = client,
            }
            game_state.players[client_player_id] = client_player

            send_network_packet_socket(client, {0, Update_Player_Data{client_player}})
            send_network_packet_socket(client, {0, Update_Player_Data{game_state.players[0]}})
            send_network_packet_socket(client, {0, Set_Client_Player_ID{client_player_id}})

            for player in game_state.players {
                // update existing players that new player has joined
                // At some point :P
            }
        }
	}
	net.close(sock)
	log.debug("Closed socket")
}

_thread_listen_socket :: proc(socket: net.TCP_Socket) {
    buf: [20 * size_of(Network_Packet)]byte
    for {  // Probably this should end at some point
        bytes_read, err := net.recv_tcp(socket, buf[:])
        if err != nil {
            log.errorf("Network receive error!")
        }
        if bytes_read >= size_of(Network_Packet) {
            packets := slice.reinterpret([]Network_Packet, buf[:bytes_read])
            sync.mutex_lock(&net_queue_mutex)
            for packet in packets {
                append(&network_queue, packet)
            }
            sync.mutex_unlock(&net_queue_mutex)
        }
    }
}

add_socket_listener :: proc(socket: net.TCP_Socket) {
    thread.create_and_start_with_poly_data(socket, _thread_listen_socket)
}

process_network_packets :: proc() {

    sync.mutex_lock(&net_queue_mutex) 
    defer sync.mutex_unlock(&net_queue_mutex)

    for packet in network_queue {
        log.infof("NET: %v", reflect.union_variant_typeid(packet.event))

        if is_host && packet.sender != 0 {
            for player_id, player in game_state.players {
                if player_id != 0 && player_id != packet.sender {
                    send_network_packet_socket(player.socket, packet)
                }
            }
        }

        switch event in packet.event {
        case Set_Client_Player_ID:
            if !is_host {
                my_player_id = event.player_id
            }
        case Update_Player_Data:
            game_state.players[event.player.id] = event.player
        case Event:
            append(&event_queue, event)
        }
    }
    clear(&network_queue)

}