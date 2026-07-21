AF_INET equ 2
SOCK_STREAM equ 1
IPPROTO_TCP equ 6
SOL_SOCKET equ 0FFFFh
SO_RCVTIMEO equ 1006h
WSAETIMEDOUT equ 10060
STD_OUTPUT_HANDLE equ -11
INVALID_SOCKET equ -1
SOCKET_ERROR equ -1

extrn WSAStartup:proc
extrn WSACleanup:proc
extrn socket:proc
extrn bind:proc
extrn listen:proc
extrn accept:proc
extrn recv:proc
extrn send:proc
extrn setsockopt:proc
extrn WSAGetLastError:proc
extrn closesocket:proc

extrn GetStdHandle:proc
extrn WriteFile:proc
extrn lstrlenA:proc
extrn ExitProcess:proc

.data
startup_msg db "bitsoup v0.0.1 | vs 1.22.4 | meow", 13, 10, 0
wsa_ok_msg db "bitsoup: WSAStartup mint", 13, 10, 0
socket_ok_msg db "bitsoup: socket crispy", 13, 10, 0
bind_ok_msg db "bitsoup: bind solid", 13, 10, 0
listen_ok_msg db "bitsoup: listen okey", 13, 10, 0
listen_msg db "bitsoup: listening on 127.0.0.1:42420", 13, 10, 0
accept_msg db "bitsoup: client connected", 13, 10, 0
recv_msg db "bitsoup: received bytes from client", 13, 10, 0
client_summary_label db "bitsoup: client ip=", 0
name_part db " name=", 0
uid_part db " uid=", 0
md_part db " md=", 0
net_part db " net=", 0
game_part db " game=", 0
unknown_value db "?", 0
dot db ".", 0
partial_frame_msg db "bitsoup: waiting for the rest of the TCP frame", 13, 10, 0
full_frame_msg db "bitsoup: complete Vintage Story TCP frame", 13, 10, 0
compressed_frame_msg db "bitsoup: frame has compression flag set", 13, 10, 0
initial_key_ok_msg db "bitsoup: first packet key looks like Vintage Story", 13, 10, 0
initial_key_bad_msg db "bitsoup: first packet key is not expected for a new VS client", 13, 10, 0
client_id_msg db "bitsoup: decoded Packet_Client.Id field", 13, 10, 0
login_token_query_msg db "bitsoup: Packet_Client.Id = LoginTokenQuery", 13, 10, 0
token_answer_msg db "bitsoup: sent Packet_Server.Id = TokenAnswer", 13, 10, 0
player_identification_msg db "bitsoup: Packet_Client.Id = PlayerIdentification", 13, 10, 0
ping_reply_msg db "bitsoup: Packet_Client.Id = PingReply", 13, 10, 0
identification_field_msg db "bitsoup: Packet_Client.Identification field is present", 13, 10, 0
join_bootstrap_msg db "bitsoup: serving bootstrap world", 13, 10, 0
join_ready_msg db "bitsoup: bootstrap sent, waiting for the client to survive", 13, 10, 0
client_loaded_msg db "bitsoup: client entered the void, serving one suspicious granite platform", 13, 10, 0
newline db 13, 10, 0
close_msg db "bitsoup: client disconnected", 13, 10, 0
fail_msg db "bitsoup: winsock/server setup failed", 13, 10, 0

stdout_handle dq 0
listen_socket dq 0
client_socket dq 0
written dd 0
last_recv dd 0
receive_timeout dd 1000
frame_bytes dd 0
frame_len dd 0
frame_compressed dd 0
parse_pos dq 0
parse_end dq 0
parsed_value dd 0
saved_ident_end dq 0
saved_outer_end dq 0
player_name_ptr dq 0
player_name_len dd 0
player_uid_ptr dq 0
player_uid_len dd 0
md_protocol_ptr dq 0
md_protocol_len dd 0
network_version_ptr dq 0
network_version_len dd 0
game_version_ptr dq 0
game_version_len dd 0
client_addr_len dd 16
client_addr dw 0
    dw 0
    dd 0
    dq 0
u8_buffer db 3 dup(0)
wsa_data db 512 dup(0)
recv_buffer db 4096 dup(0)
frame_buffer db 65536 dup(0)

; login token reply. this much wrapping for one string is apparently necessary
; id 77 is TokenAnswer
; the token itself is just "bitsoup-token"
token_answer_packet db 00h, 00h, 00h, 15h
    db 0D0h, 05h, 4Dh
    db 0EAh, 04h, 0Fh
    db 0Ah, 0Dh
    db "bitsoup-token"

; server identification. the client needs this before it will believe any of us
; allowMap is false until we have something less insulting than no map server
server_identification_packet db 00h, 00h, 00h, 59h
    db 0Ah, 57h
    db 0Ah, 06h, "1.22.6"
    db 8Ah, 01h, 06h, "1.22.4"
    db 1Ah, 07h, "BitSoup"
    db 38h, 80h, 08h
    db 40h, 80h, 02h
    db 48h, 80h, 08h
    db 0A8h, 01h, 10h
    db 0B0h, 01h, 10h
    db 0B8h, 01h, 10h
    db 68h, 01h
    db 82h, 01h, 08h, "survival"
    db 0A2h, 01h, 0Ch, 09h, 08h, "allowMap", 00h, 00h
    db 0C2h, 01h, 0Ch, "bitsoup-save"

; id 73 means ServerReady. yes the empty packet matters
server_ready_packet db 00h, 00h, 00h, 06h
    db 0D0h, 05h, 49h
    db 0CAh, 04h, 00h

; id 56 connects the two mod channels we can currently fake with a straight face
network_channels_packet db 00h, 00h, 00h, 22h, 0D0h, 05h, 38h, 0C2h, 03h, 1Ch
    db 08h, 01h, 08h, 02h
    db 12h, 07h, "weather"
    db 12h, 0Dh, "charselection"

; id 51 gives the coordinate HUD a real global spawn instead of a null pointer
; positions use blocks times 16384 because normal numbers were too approachable
spawn_position_packet db 00h, 00h, 00h, 19h, 0D0h, 05h, 33h, 9Ah, 03h, 13h, 08h, 01h
    db 10h, 80h, 80h, 80h, 04h, 18h, 80h, 80h, 70h, 20h, 80h, 80h
    db 80h, 04h, 92h, 01h, 00h

; id 2 is the whole keepalive packet. the nested ping contains absolutely nothing
ping_packet db 00h, 00h, 00h, 06h, 0D0h, 05h, 02h, 82h, 01h, 00h

; tell survival that the default character is already picked
; otherwise it opens a dress-up screen for the player model we do not have yet
character_selected_packet db 00h, 00h, 00h, 0Eh, 0D0h, 05h, 37h, 0BAh, 03h, 08h, 08h, 02h
    db 10h, 01h, 1Ah, 02h, 08h, 01h

; its just too large to fit here, cant i have SOME space
include weather-packet.inc

; id 4 sets 32 block chunks, 512 block regions, and a 128 block view distance
; yes the client divides by this stuff later. 16 looked innocent and absolutely was not
level_initialize_packet db 00h, 00h, 00h, 0Fh
    db 0D0h, 05h, 04h
    db 12h, 0Ah
    db 08h, 20h
    db 10h, 20h
    db 18h, 80h, 04h
    db 20h, 80h, 01h

; id 5 says loading hit 100 percent
; this looked cosmetic. it was not. without it half the client never wakes up
level_progress_packet db 00h, 00h, 00h, 1Ch
    db 0D0h, 05h, 05h
    db 1Ah, 17h
    db 10h, 64h
    db 1Ah, 13h, "Generating world..."

; id 21 carries world config and the light lookup tables
; yes even a world made entirely of air needs 64 tiny brightness numbers
world_metadata_packet db 00h, 00h, 00h, 99h
    db 0D0h, 05h, 15h
    db 0AAh, 01h, 92h, 01h
    db 08h, 18h

    db 10h, 03h, 10h, 06h, 10h, 09h, 10h, 0Bh
    db 10h, 0Eh, 10h, 10h, 10h, 13h, 10h, 15h
    db 10h, 18h, 10h, 1Bh, 10h, 1Dh, 10h, 20h
    db 10h, 22h, 10h, 25h, 10h, 27h, 10h, 2Ah
    db 10h, 2Ch, 10h, 2Fh, 10h, 32h, 10h, 34h
    db 10h, 37h, 10h, 39h, 10h, 3Ch, 10h, 3Fh
    db 10h, 40h, 10h, 40h, 10h, 40h, 10h, 40h
    db 10h, 40h, 10h, 40h, 10h, 40h, 10h, 40h

    db 18h, 03h, 18h, 06h, 18h, 09h, 18h, 0Bh
    db 18h, 0Eh, 18h, 10h, 18h, 13h, 18h, 15h
    db 18h, 18h, 18h, 1Bh, 18h, 1Dh, 18h, 20h
    db 18h, 22h, 18h, 25h, 18h, 27h, 18h, 2Ah
    db 18h, 2Ch, 18h, 2Fh, 18h, 32h, 18h, 34h
    db 18h, 37h, 18h, 39h, 18h, 3Ch, 18h, 3Fh
    db 18h, 40h, 18h, 40h, 18h, 40h, 18h, 40h
    db 18h, 40h, 18h, 40h, 18h, 40h, 18h, 40h

    db 22h, 0Ch, 09h, 08h, "allowMap", 00h, 00h
    db 28h, 6Eh

include assets-packet.inc

; id 40 spawns our one lonely EntityPlayer
; the stat trees keep the HUD from asking a null oxygen bar to hide itself
; the real UID still gets copied into the 24 byte hole at offset 78
entities_packet db 00h, 00h, 01h, 0BAh, 0D0h, 05h, 28h, 0C2h, 02h, 0B3h, 03h, 0Ah
    db 0B0h, 03h, 0Ah, 06h, 70h, 6Ch, 61h, 79h, 65h, 72h, 10h, 01h
    db 18h, 80h, 01h, 22h, 0A0h, 03h, 01h, 00h, 00h, 00h, 00h, 00h
    db 00h, 00h, 04h, 07h, 68h, 65h, 61h, 64h, 59h, 61h, 77h, 00h
    db 00h, 00h, 00h, 04h, 09h, 68h, 65h, 61h, 64h, 50h, 69h, 74h
    db 63h, 68h, 00h, 00h, 00h, 00h, 05h, 09h, 70h, 6Ch, 61h, 79h
    db 65h, 72h, 55h, 49h, 44h, 18h, 30h, 30h, 30h, 30h, 30h, 30h
    db 30h, 30h, 30h, 30h, 30h, 30h, 30h, 30h, 30h, 30h, 30h, 30h
    db 30h, 30h, 30h, 30h, 30h, 30h, 06h, 06h, 68h, 65h, 61h, 6Ch
    db 74h, 68h, 04h, 0Dh, 63h, 75h, 72h, 72h, 65h, 6Eh, 74h, 68h
    db 65h, 61h, 6Ch, 74h, 68h, 00h, 00h, 0A0h, 41h, 04h, 09h, 6Dh
    db 61h, 78h, 68h, 65h, 61h, 6Ch, 74h, 68h, 00h, 00h, 0A0h, 41h
    db 04h, 0Dh, 62h, 61h, 73h, 65h, 6Dh, 61h, 78h, 68h, 65h, 61h
    db 6Ch, 74h, 68h, 00h, 00h, 0A0h, 41h, 04h, 13h, 70h, 72h, 65h
    db 76h, 69h, 6Fh, 75h, 73h, 48h, 65h, 61h, 6Ch, 74h, 68h, 56h
    db 61h, 6Ch, 75h, 65h, 00h, 00h, 0A0h, 41h, 04h, 14h, 68h, 65h
    db 61h, 6Ch, 74h, 68h, 43h, 68h, 61h, 6Eh, 67h, 65h, 56h, 65h
    db 6Ch, 6Fh, 63h, 69h, 74h, 79h, 00h, 00h, 00h, 00h, 00h, 06h
    db 06h, 68h, 75h, 6Eh, 67h, 65h, 72h, 04h, 11h, 63h, 75h, 72h
    db 72h, 65h, 6Eh, 74h, 73h, 61h, 74h, 75h, 72h, 61h, 74h, 69h
    db 6Fh, 6Eh, 00h, 80h, 0BBh, 44h, 04h, 0Dh, 6Dh, 61h, 78h, 73h
    db 61h, 74h, 75h, 72h, 61h, 74h, 69h, 6Fh, 6Eh, 00h, 80h, 0BBh
    db 44h, 00h, 06h, 06h, 6Fh, 78h, 79h, 67h, 65h, 6Eh, 04h, 0Dh
    db 63h, 75h, 72h, 72h, 65h, 6Eh, 74h, 6Fh, 78h, 79h, 67h, 65h
    db 6Eh, 00h, 40h, 1Ch, 47h, 04h, 09h, 6Dh, 61h, 78h, 6Fh, 78h
    db 79h, 67h, 65h, 6Eh, 00h, 40h, 1Ch, 47h, 00h, 00h, 00h, 00h
    db 00h, 00h, 00h, 00h, 80h, 40h, 00h, 00h, 00h, 00h, 00h, 00h
    db 5Ch, 40h, 00h, 00h, 00h, 00h, 00h, 00h, 80h, 40h, 00h, 00h
    db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
    db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
    db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
    db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 80h, 40h, 00h, 00h
    db 00h, 00h, 00h, 00h, 5Ch, 40h, 00h, 00h, 00h, 00h, 00h, 00h
    db 80h, 40h, 06h, 70h, 6Ch, 61h, 79h, 65h, 72h, 00h, 00h, 00h
    db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
    db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
    db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
    db 00h, 00h
entity_uid_patch equ entities_packet + 78

; id 41 tells the client that entity 1 is actually its own player
; creative flight and noclip let us move while the whole world is still air
; the HUD expects all seven inventories even when every slot is painfully empty
; one boring privilege also keeps the world map from calling IndexOf on null
player_data_packet db 00h, 00h, 01h, 0A6h, 0D0h, 05h, 29h, 0CAh, 02h, 9Fh, 03h
    db 08h, 01h, 10h, 01h, 18h, 02h, 20h, 40h, 28h, 01h, 30h, 01h

    db 3Ah, 2Bh, 08h, 01h, 12h, 06h, "hotbar", 1Ah, 1Fh, "hotbar-"
hotbar_uid_patch db "000000000000000000000000"
    db 3Ah, 2Fh, 08h, 01h, 12h, 08h, "creative", 1Ah, 21h, "creative-"
creative_uid_patch db "000000000000000000000000"
    db 3Ah, 2Fh, 08h, 01h, 12h, 08h, "backpack", 1Ah, 21h, "backpack-"
backpack_uid_patch db "000000000000000000000000"
    db 3Ah, 2Bh, 08h, 01h, 12h, 06h, "ground", 1Ah, 1Fh, "ground-"
ground_uid_patch db "000000000000000000000000"
    db 3Ah, 29h, 08h, 01h, 12h, 05h, "mouse", 1Ah, 1Eh, "mouse-"
mouse_uid_patch db "000000000000000000000000"
    db 3Ah, 37h, 08h, 01h, 12h, 0Ch, "craftinggrid", 1Ah, 25h, "craftinggrid-"
craftinggrid_uid_patch db "000000000000000000000000"
    db 3Ah, 31h, 08h, 01h, 12h, 09h, "character", 1Ah, 22h, "character-"
character_uid_patch db "000000000000000000000000"

    db 42h, 18h
playerdata_uid_patch db "000000000000000000000000"
    db 48h, 0C0h, 02h, 62h, 0Bh, "buildblocks", 88h, 01h, 80h, 04h, 90h, 01h, 70h, 98h, 01h
    db 80h, 04h, 0A2h, 01h, 08h, 73h, 75h, 70h, 6Ch, 61h, 79h, 65h
    db 72h

; id 10 sends the platform chunk and enough empty neighbors to let it mesh
include chunk-packet.inc

; id 53 picks hotbar slot zero. there is nothing in it
selected_hotbar_packet db 00h, 00h, 00h, 08h, 0D0h, 05h, 35h, 0AAh, 03h, 02h, 10h, 01h

; id 6 finalizes loading. sending this early is a fantastic way to crash the client
level_finalize_packet db 00h, 00h, 00h, 05h
    db 0D0h, 05h, 06h
    db 22h, 00h

; raw sockaddr_in for 127.0.0.1:42420
; the port bytes look backwards because x64 stores the word little endian
; same deal for the IP. memory needs 7F 00 00 01 so the literal looks reversed
server_addr dw AF_INET
    dw 0B4A5h
    dd 0100007Fh
    dq 0

.code
printz proc
    sub rsp, 56

    mov qword ptr [rsp + 40], rcx
    call lstrlenA

    mov rcx, stdout_handle
    mov rdx, qword ptr [rsp + 40]
    mov r8d, eax
    lea r9, written
    mov qword ptr [rsp + 32], 0
    call WriteFile

    add rsp, 56
    ret
printz endp

print_bytes proc
    sub rsp, 56

    mov qword ptr [rsp + 40], rcx
    mov dword ptr [rsp + 48], edx

    mov rcx, stdout_handle
    mov rdx, qword ptr [rsp + 40]
    mov r8d, dword ptr [rsp + 48]
    lea r9, written
    mov qword ptr [rsp + 32], 0
    call WriteFile

    add rsp, 56
    ret
print_bytes endp

print_u8 proc
    sub rsp, 40

    mov eax, ecx
    lea r9, u8_buffer
    cmp eax, 100
    jae print_u8_three
    cmp eax, 10
    jae print_u8_two

    add al, "0"
    mov byte ptr [r9], al
    mov edx, 1
    jmp print_u8_emit

print_u8_two:
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, "0"
    mov byte ptr [r9], al
    add dl, "0"
    mov byte ptr [r9 + 1], dl
    mov edx, 2
    jmp print_u8_emit

print_u8_three:
    xor edx, edx
    mov ecx, 100
    div ecx
    add al, "0"
    mov byte ptr [r9], al

    mov eax, edx
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, "0"
    mov byte ptr [r9 + 1], al
    add dl, "0"
    mov byte ptr [r9 + 2], dl
    mov edx, 3

print_u8_emit:
    lea rcx, u8_buffer
    call print_bytes

    add rsp, 40
    ret
print_u8 endp

print_ip_value proc
    sub rsp, 40

    movzx ecx, byte ptr [client_addr + 4]
    call print_u8
    lea rcx, dot
    call printz

    movzx ecx, byte ptr [client_addr + 5]
    call print_u8
    lea rcx, dot
    call printz

    movzx ecx, byte ptr [client_addr + 6]
    call print_u8
    lea rcx, dot
    call printz

    movzx ecx, byte ptr [client_addr + 7]
    call print_u8

    add rsp, 40
    ret
print_ip_value endp

print_optional_value proc
    sub rsp, 56

    mov qword ptr [rsp + 40], rcx
    mov dword ptr [rsp + 48], edx
    test edx, edx
    je print_optional_unknown

    mov rcx, qword ptr [rsp + 40]
    mov edx, dword ptr [rsp + 48]
    call print_bytes
    jmp print_optional_done

print_optional_unknown:
    lea rcx, unknown_value
    call printz

print_optional_done:
    add rsp, 56
    ret
print_optional_value endp

clear_identity proc
    mov player_name_ptr, 0
    mov player_name_len, 0
    mov player_uid_ptr, 0
    mov player_uid_len, 0
    mov md_protocol_ptr, 0
    mov md_protocol_len, 0
    mov network_version_ptr, 0
    mov network_version_len, 0
    mov game_version_ptr, 0
    mov game_version_len, 0
    ret
clear_identity endp

print_client_summary proc
    sub rsp, 40

    lea rcx, client_summary_label
    call printz
    call print_ip_value

    lea rcx, name_part
    call printz
    mov rcx, player_name_ptr
    mov edx, player_name_len
    call print_optional_value

    lea rcx, uid_part
    call printz
    mov rcx, player_uid_ptr
    mov edx, player_uid_len
    call print_optional_value

    lea rcx, md_part
    call printz
    mov rcx, md_protocol_ptr
    mov edx, md_protocol_len
    call print_optional_value

    lea rcx, net_part
    call printz
    mov rcx, network_version_ptr
    mov edx, network_version_len
    call print_optional_value

    lea rcx, game_part
    call printz
    mov rcx, game_version_ptr
    mov edx, game_version_len
    call print_optional_value

    lea rcx, newline
    call printz

    add rsp, 40
    ret
print_client_summary endp

fail_exit proc
    sub rsp, 40

    lea rcx, fail_msg
    call printz

    mov ecx, 1
    call ExitProcess
fail_exit endp

append_recv proc
    push rsi
    push rdi

    lea rdi, frame_buffer
    mov eax, frame_bytes
    add rdi, rax
    lea rsi, recv_buffer
    mov ecx, last_recv

append_recv_loop:
    test ecx, ecx
    je append_recv_done
    mov al, byte ptr [rsi]
    mov byte ptr [rdi], al
    inc rsi
    inc rdi
    dec ecx
    jmp append_recv_loop

append_recv_done:
    mov eax, frame_bytes
    add eax, last_recv
    mov frame_bytes, eax
    pop rdi
    pop rsi
    ret
append_recv endp

parse_frame_header proc
    movzx eax, byte ptr [frame_buffer]
    mov ecx, eax
    and ecx, 80h
    mov frame_compressed, ecx

    and eax, 7Fh
    shl eax, 24

    movzx ecx, byte ptr [frame_buffer + 1]
    shl ecx, 16
    or eax, ecx

    movzx ecx, byte ptr [frame_buffer + 2]
    shl ecx, 8
    or eax, ecx

    movzx ecx, byte ptr [frame_buffer + 3]
    or eax, ecx

    mov frame_len, eax
    ret
parse_frame_header endp

clear_frame proc
    mov frame_bytes, 0
    mov frame_len, 0
    mov frame_compressed, 0
    ret
clear_frame endp

consume_frame proc
    push rsi
    push rdi

    mov eax, frame_len
    add eax, 4
    mov ecx, frame_bytes
    sub ecx, eax
    jle consume_frame_clear

    lea rsi, frame_buffer
    add rsi, rax
    lea rdi, frame_buffer

consume_frame_loop:
    test ecx, ecx
    je consume_frame_done
    mov al, byte ptr [rsi]
    mov byte ptr [rdi], al
    inc rsi
    inc rdi
    dec ecx
    jmp consume_frame_loop

consume_frame_done:
    lea rax, frame_buffer
    sub rdi, rax
    mov frame_bytes, edi
    mov frame_len, 0
    mov frame_compressed, 0
    pop rdi
    pop rsi
    ret

consume_frame_clear:
    call clear_frame
    pop rdi
    pop rsi
    ret
consume_frame endp

send_token_answer proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, token_answer_packet
    mov r8d, 25
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_token_answer endp

send_server_identification proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, server_identification_packet
    mov r8d, 93
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_server_identification endp

send_server_ready proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, server_ready_packet
    mov r8d, 10
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_server_ready endp

send_network_channels proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, network_channels_packet
    mov r8d, 38
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_network_channels endp

send_spawn_position proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, spawn_position_packet
    mov r8d, 29
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_spawn_position endp

send_ping proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, ping_packet
    mov r8d, 10
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_ping endp

send_character_selected proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, character_selected_packet
    mov r8d, 18
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_character_selected endp

send_weather_assets proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, weather_assets_packet
    mov r8d, 4464
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_weather_assets endp

send_level_initialize proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, level_initialize_packet
    mov r8d, 19
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_level_initialize endp

send_level_progress proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, level_progress_packet
    mov r8d, 32
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_level_progress endp

send_world_metadata proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, world_metadata_packet
    mov r8d, 157
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_world_metadata endp

send_server_assets proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, server_assets_packet
    mov r8d, server_assets_packet_size
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_server_assets endp

send_entities proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, entities_packet
    mov r8d, 446
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_entities endp

send_player_data proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, player_data_packet
    mov r8d, 426
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_player_data endp

send_spawn_chunk proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, spawn_chunk_packet
    mov r8d, spawn_chunk_packet_size
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_spawn_chunk endp

send_selected_hotbar proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, selected_hotbar_packet
    mov r8d, 12
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_selected_hotbar endp

send_level_finalize proc
    sub rsp, 40

    mov rcx, client_socket
    lea rdx, level_finalize_packet
    mov r8d, 9
    xor r9d, r9d
    call send

    add rsp, 40
    ret
send_level_finalize endp

copy_uid24 proc
    mov rsi, player_uid_ptr
    mov ecx, 24

copy_uid24_loop:
    mov al, byte ptr [rsi]
    mov byte ptr [rdi], al
    inc rsi
    inc rdi
    loop copy_uid24_loop
    ret
copy_uid24 endp

patch_uid_placeholders proc
    cmp player_uid_len, 24
    jne patch_uid_done
    cmp player_uid_ptr, 0
    je patch_uid_done

    push rsi
    push rdi

    lea rdi, entity_uid_patch
    call copy_uid24
    lea rdi, playerdata_uid_patch
    call copy_uid24
    lea rdi, hotbar_uid_patch
    call copy_uid24
    lea rdi, creative_uid_patch
    call copy_uid24
    lea rdi, backpack_uid_patch
    call copy_uid24
    lea rdi, ground_uid_patch
    call copy_uid24
    lea rdi, mouse_uid_patch
    call copy_uid24
    lea rdi, craftinggrid_uid_patch
    call copy_uid24
    lea rdi, character_uid_patch
    call copy_uid24

    pop rdi
    pop rsi

patch_uid_done:
    ret
patch_uid_placeholders endp

read_varint proc
    xor eax, eax
    xor ecx, ecx
    mov rdx, parse_pos

read_varint_loop:
    mov r8, parse_end
    cmp rdx, r8
    jae read_varint_fail

    movzx r8d, byte ptr [rdx]
    inc rdx

    mov r9d, r8d
    and r9d, 7Fh
    shl r9d, cl
    or eax, r9d

    test r8b, 80h
    je read_varint_done

    add ecx, 7
    cmp ecx, 28
    jle read_varint_loop

read_varint_done:
    mov parse_pos, rdx
    mov parsed_value, eax
    mov eax, 1
    ret

read_varint_fail:
    xor eax, eax
    ret
read_varint endp

skip_length_delimited proc
    call read_varint
    test eax, eax
    je skip_length_done

    mov rax, parse_pos
    mov ecx, parsed_value
    add rax, rcx
    mov parse_pos, rax

skip_length_done:
    ret
skip_length_delimited endp

parse_identification proc
    sub rsp, 40

parse_identification_loop:
    mov rax, parse_pos
    mov rcx, parse_end
    cmp rax, rcx
    jae parse_identification_done

    call read_varint
    test eax, eax
    je parse_identification_done

    mov ecx, parsed_value
    cmp ecx, 10
    je ident_md_protocol
    cmp ecx, 18
    je ident_player_name
    cmp ecx, 26
    je ident_skip_string
    cmp ecx, 34
    je ident_skip_string
    cmp ecx, 50
    je ident_player_uid
    cmp ecx, 56
    je ident_skip_varint
    cmp ecx, 64
    je ident_skip_varint
    cmp ecx, 74
    je ident_network_version
    cmp ecx, 82
    je ident_game_version

    mov eax, ecx
    and eax, 7
    cmp eax, 0
    je ident_skip_varint
    cmp eax, 2
    je ident_skip_string
    jmp parse_identification_done

ident_md_protocol:
    call read_varint
    test eax, eax
    je parse_identification_done
    mov rax, parse_pos
    mov md_protocol_ptr, rax
    mov eax, parsed_value
    mov md_protocol_len, eax
    jmp ident_advance_string

ident_player_name:
    call read_varint
    test eax, eax
    je parse_identification_done
    mov rax, parse_pos
    mov player_name_ptr, rax
    mov eax, parsed_value
    mov player_name_len, eax
    jmp ident_advance_string

ident_player_uid:
    call read_varint
    test eax, eax
    je parse_identification_done
    mov rax, parse_pos
    mov player_uid_ptr, rax
    mov eax, parsed_value
    mov player_uid_len, eax
    jmp ident_advance_string

ident_network_version:
    call read_varint
    test eax, eax
    je parse_identification_done
    mov rax, parse_pos
    mov network_version_ptr, rax
    mov eax, parsed_value
    mov network_version_len, eax
    jmp ident_advance_string

ident_game_version:
    call read_varint
    test eax, eax
    je parse_identification_done
    mov rax, parse_pos
    mov game_version_ptr, rax
    mov eax, parsed_value
    mov game_version_len, eax
    jmp ident_advance_string

ident_advance_string:
    mov rax, parse_pos
    mov ecx, parsed_value
    add rax, rcx
    mov parse_pos, rax
    jmp parse_identification_loop

ident_skip_string:
    call skip_length_delimited
    jmp parse_identification_loop

ident_skip_varint:
    call read_varint
    jmp parse_identification_loop

parse_identification_done:
    call print_client_summary
    call send_server_identification
    call send_server_ready
    add rsp, 40
    ret
parse_identification endp

parse_client_packet proc
    sub rsp, 40

    lea rax, frame_buffer + 4
    mov parse_pos, rax
    mov ecx, frame_len
    add rax, rcx
    mov parse_end, rax

parse_client_loop:
    mov rax, parse_pos
    mov rcx, parse_end
    cmp rax, rcx
    jae parse_client_done

    call read_varint
    test eax, eax
    je parse_client_done

    mov ecx, parsed_value
    cmp ecx, 8
    je parse_client_id
    cmp ecx, 18
    je parse_client_identification

    mov eax, ecx
    and eax, 7
    cmp eax, 0
    je parse_client_skip_varint
    cmp eax, 2
    je parse_client_skip_string
    jmp parse_client_done

parse_client_id:
    call read_varint
    test eax, eax
    je parse_client_done

    mov ecx, parsed_value
    cmp ecx, 1
    je parse_client_id_player_identification
    cmp ecx, 2
    je parse_client_id_ping_reply
    cmp ecx, 11
    je parse_client_id_request_join
    cmp ecx, 26
    je parse_client_id_client_loaded
    cmp ecx, 33
    je parse_client_id_login_token_query
    jmp parse_client_loop

parse_client_id_login_token_query:
    call send_token_answer
    jmp parse_client_loop

parse_client_id_player_identification:
    jmp parse_client_loop

parse_client_id_ping_reply:
    jmp parse_client_loop

parse_client_id_client_loaded:
    lea rcx, client_loaded_msg
    call printz
    call send_spawn_chunk
    jmp parse_client_loop

parse_client_id_request_join:
    lea rcx, join_bootstrap_msg
    call printz
    call patch_uid_placeholders
    call send_network_channels
    call send_spawn_position
    call send_level_initialize
    call send_level_progress
    call send_world_metadata
    call send_server_assets
    call send_entities
    call send_character_selected
    call send_player_data
    call send_weather_assets
    call send_selected_hotbar
    call send_level_finalize
    lea rcx, join_ready_msg
    call printz
    jmp parse_client_loop

parse_client_identification:
    call read_varint
    test eax, eax
    je parse_client_done

    mov rax, parse_pos
    mov ecx, parsed_value
    add rax, rcx
    mov saved_ident_end, rax
    mov rax, parse_end
    mov saved_outer_end, rax
    mov rax, saved_ident_end
    mov parse_end, rax

    call parse_identification

    mov rax, saved_ident_end
    mov parse_pos, rax
    mov rax, saved_outer_end
    mov parse_end, rax
    jmp parse_client_loop

parse_client_skip_string:
    call skip_length_delimited
    jmp parse_client_loop

parse_client_skip_varint:
    call read_varint
    jmp parse_client_loop

parse_client_done:
    call consume_frame
    add rsp, 40
    ret
parse_client_packet endp

main proc
    and rsp, -16
    sub rsp, 48

    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov stdout_handle, rax

    lea rcx, startup_msg
    call printz

    mov ecx, 0202h
    lea rdx, wsa_data
    call WSAStartup
    test eax, eax
    jne setup_failed
    lea rcx, wsa_ok_msg
    call printz

    mov ecx, AF_INET
    mov edx, SOCK_STREAM
    mov r8d, IPPROTO_TCP
    call socket
    cmp rax, INVALID_SOCKET
    je setup_failed
    mov listen_socket, rax
    lea rcx, socket_ok_msg
    call printz

    mov rcx, listen_socket
    lea rdx, server_addr
    mov r8d, 16
    call bind
    cmp eax, SOCKET_ERROR
    je setup_failed
    lea rcx, bind_ok_msg
    call printz

    mov rcx, listen_socket
    mov edx, 10
    call listen
    cmp eax, SOCKET_ERROR
    je setup_failed
    lea rcx, listen_ok_msg
    call printz

    lea rcx, listen_msg
    call printz

accept_loop:
    mov rcx, listen_socket
    mov client_addr_len, 16
    lea rdx, client_addr
    lea r8, client_addr_len
    call accept
    cmp rax, INVALID_SOCKET
    je accept_loop
    mov client_socket, rax

    ; waking recv once a second is our tiny excuse for having a game loop
    mov rcx, client_socket
    mov edx, SOL_SOCKET
    mov r8d, SO_RCVTIMEO
    lea r9, receive_timeout
    mov dword ptr [rsp + 32], 4
    call setsockopt

    call clear_frame
    call clear_identity

recv_loop:
    mov rcx, client_socket
    lea rdx, recv_buffer
    mov r8d, 4096
    xor r9d, r9d
    call recv
    cmp eax, 0
    jg recv_got_bytes
    je client_closed

    call WSAGetLastError
    cmp eax, WSAETIMEDOUT
    jne client_closed
    call send_ping
    jmp recv_loop

recv_got_bytes:
    mov last_recv, eax

    call append_recv

try_parse_frame:
    cmp frame_bytes, 4
    jl partial_frame

    call parse_frame_header

    mov eax, frame_len
    add eax, 4
    cmp frame_bytes, eax
    jl partial_frame

    cmp frame_compressed, 0
    je check_initial_key

    lea rcx, compressed_frame_msg
    call printz

check_initial_key:
    cmp frame_len, 1
    jl partial_frame

    movzx ecx, byte ptr [frame_buffer + 4]
    cmp ecx, 8
    je parse_complete_frame
    cmp ecx, 18
    je parse_complete_frame

    lea rcx, initial_key_bad_msg
    call printz
    call consume_frame
    cmp frame_bytes, 0
    jne try_parse_frame
    jmp recv_loop

parse_complete_frame:
    call parse_client_packet
    cmp frame_bytes, 0
    jne try_parse_frame
    jmp recv_loop

partial_frame:
    jmp recv_loop

client_closed:
    mov rcx, client_socket
    call closesocket

    lea rcx, close_msg
    call printz
    jmp accept_loop

setup_failed:
    call fail_exit
main endp

end
