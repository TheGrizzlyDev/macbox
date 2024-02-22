package rpc

import (
	"bufio"
	"errors"
	"io"
	"net"
	"os"
	"os/signal"
	"syscall"

	"google.golang.org/protobuf/proto"

	rpcprotocol "github.com/TheGrizzlyDev/macbox/proto/protocol/v1"
	"google.golang.org/protobuf/types/known/anypb"
)

type RpcHandler interface {
	Handle(anypb.Any) (anypb.Any, error)
}

type rpcHnadlerFnType = func(anypb.Any) (anypb.Any, error)

type rpcHandlerFnWrapper struct {
	fn rpcHnadlerFnType
}

func (r rpcHandlerFnWrapper) Handle(req anypb.Any) (anypb.Any, error) {
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
		panic(err)
	}()

	for {
		conn, err := managementSocket.Accept()
		if err != nil {
			return err
		}

		go func(conn net.Conn) {
			defer conn.Close()
			for {
				reader := bufio.NewReader(conn)
				requestBytes, err := reader.ReadBytes('\n')
				isEof := false
				if err != nil {
					if errors.Is(err, io.EOF) {
						isEof = true
					} else {
						panic(err) // todo: propagate error instead
					}
				}
				request := rpcprotocol.Request{}
				proto.Unmarshal(requestBytes, &request)

				var responsePayload anypb.Any
				if handler, ok := u.handlers[request.Method]; ok {
					responsePayload, err = handler.Handle(request.Payload)
				} else {
					responsePayload, err = u.fallback.Handle(request.Payload)
				}
				if err != nil {
					panic(err) // todo: do something about it
				}

				response := rpcprotocol.Response{
					Payload: &responsePayload,
				}
				resBytes, err := proto.Marshal(response)
				conn.Write(resBytes)
				conn.Write([]byte{'\n'})

				if isEof {
					return
				}
			}
		}(conn)
	}
}
