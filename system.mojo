from sys.ffi import DLHandle, external_call

var libc = DLHandle("/lib/x86_64-linux-gnu/libc.so.6")

var AF_INET: Int = 2
var SOCK_STREAM: Int = 1
var IPPROTO_TCP: Int = 6

struct sockaddr_in:
    sin_family: UInt16
    sin_port: UInt16
    sin_addr: UInt32
    sin_zero: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)

fn htons(hostshort: UInt16) -> UInt16:
    return external_call["htons", UInt16](hostshort)

fn inet_addr(cp: String) -> UInt32:
    return external_call["inet_addr", UInt32](cp)

struct Socket:
    var fd: Int

    fn __init__(inout self, domain: Int, type: Int, protocol: Int):
        self.fd = external_call["socket", Int](domain, type, protocol)
        if self.fd < 0:
            raise Error("Falha ao criar o socket")

    fn connect(inout self, addr: UnsafePointer[sockaddr_in], addrlen: Int):
        result = external_call["connect", Int](self.fd, addr, addrlen)
        if result < 0:
            raise Error("Falha ao conectar ao servidor")

    fn send(inout self, buf: UnsafePointer[UInt8], len: Int, flags: Int = 0) -> Int:
        return external_call["send", Int](self.fd, buf, len, flags)

    fn recv(inout self, buf: UnsafePointer[UInt8], len: Int, flags: Int = 0) -> Int:
        return external_call["recv", Int](self.fd, buf, len, flags)

    fn close(inout self):
        external_call["close", Int](self.fd)

fn main():
    var sock = Socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)

    var server_addr = UnsafePointer[sockaddr_in].alloc(1)
    initialize_pointee_copy(server_addr, sockaddr_in(
        sin_family=AF_INET,
        sin_port=htons(8080),
        sin_addr=inet_addr("127.0.0.1"),
        sin_zero=(0, 0, 0, 0, 0, 0, 0, 0)
    ))

    sock.connect(server_addr, sizeof(sockaddr_in))

    var message = "Hello, Server!"
    var buf = UnsafePointer[UInt8].alloc(len(message))
    for i in range(len(message)):
        initialize_pointee_copy(buf + i, message[i])
    sock.send(buf, len(message))

    var recv_buf = UnsafePointer[UInt8].alloc(1024)
    var received_len = sock.recv(recv_buf, 1024)
    var response = String()
    for i in range(received_len):
        response += recv_buf[i].to_str()
    print(response)

    sock.close()