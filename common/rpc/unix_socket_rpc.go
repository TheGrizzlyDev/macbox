package rpc

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"

	"google.golang.org/protobuf/proto"

	rpcprotocol "github.com/TheGrizzlyDev/macbox/proto/protocol/v1"
)

type RpcHandler interface {
	Handle([]byte) ([]byte, error)
}

type rpcHnadlerFnType = func([]byte) ([]byte, error)

type rpcHandlerFnWrapper struct {
	fn rpcHnadlerFnType
}

func (r rpcHandlerFnWrapper) Handle(req []byte) ([]byte, error) {
	return r.fn(req)
}

func RpcHandlerFn(fn rpcHnadlerFnType) RpcHandler {
	return rpcHandlerFnWrapper{fn}
}

type UnixSocketRpcServer struct {
	socketPath string
	handlers   map[string]RpcHandler
	fallback   RpcHandler
}

func NewUnixSocketRpcServer(path string) *UnixSocketRpcServer {
	return &UnixSocketRpcServer{
		socketPath: path,
		handlers:   make(map[string]RpcHandler),
	}
}

func (u *UnixSocketRpcServer) AddHandler(method string, handler RpcHandler) *UnixSocketRpcServer {
	u.handlers[method] = handler
	return u
}

func (u *UnixSocketRpcServer) AddFallbackHandler(handler RpcHandler) *UnixSocketRpcServer {
	u.fallback = handler
	return u
}

func (u *UnixSocketRpcServer) Listen() error {
	managementSocket, err := net.Listen("unix", u.socketPath)
	if err != nil {
		return err
	}

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		os.Remove(u.socketPath)
		os.Exit(1)
	}()

	for {
		fmt.Println("Waiting for a connection")
		conn, err := managementSocket.Accept()
		if err != nil {
			return err
		}

		fmt.Println("Opened connection")
		go func(conn net.Conn) {
			defer conn.Close()
			for {
				reader := bufio.NewReader(conn)
				requestBytes, err := reader.ReadBytes('\n')
				if err != nil {
					os.Exit(1) // todo: propagate error instead
				}
				fmt.Println(requestBytes)
				request := rpcprotocol.Request{}
				proto.Unmarshal(requestBytes, &request)
				fmt.Println(request)
			}
			// deserialize blob into `protocol.v1.Request`
			// read method and payload accordingly
		}(conn)
	}
}
