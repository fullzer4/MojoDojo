from memory.unsafe_pointer import UnsafePointer, initialize_pointee_copy
from system import linux

fn main():
    # Criação do socket
    var sock = Socket(linux.AF_INET, linux.SOCK_STREAM, 0)

    # Definição do endereço do servidor
    var server_addr = UnsafePointer[linux.sockaddr_in].alloc(1)
    initialize_pointee_copy(server_addr, linux.sockaddr_in(
        sin_family=linux.AF_INET,
        sin_port=linux.htons(8080),
        sin_addr=linux.in_addr(s_addr=linux.inet_addr("127.0.0.1")),
        sin_zero=(0, 0, 0, 0, 0, 0, 0, 0)
    ))

    # Conexão ao servidor
    sock.connect(server_addr, sizeof(linux.sockaddr_in))

    # Envio de dados
    var message = "Hello, Server!"
    var buf = UnsafePointer[UInt8].alloc(len(message))
    for i in range(len(message)):
        initialize_pointee_copy(buf + i, message[i])
    sock.send(buf, len(message))

    # Recebimento de dados
    var recv_buf = UnsafePointer[UInt8].alloc(1024)
    var received_len = sock.recv(recv_buf, 1024)
    var response = String()
    for i in range(received_len):
        response += recv_buf[i].to_str()
    print(response)

    # Fechamento do socket
    sock.close()