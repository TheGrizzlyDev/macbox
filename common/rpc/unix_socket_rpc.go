package rpc

import (
	"context"
	"encoding/binary"
	"errors"
	"fmt"
	"io"
	"net"
	"os"
	"sync"

	"google.golang.org/protobuf/proto"

	rpcprotocol "github.com/TheGrizzlyDev/macbox/proto/protocol/v1"
)

type RpcHandler interface {
	Handle([]byte) (proto.Message, error)
}

type rpcHnadlerFnType = func([]byte) (proto.Message, error)

type rpcHandlerFnWrapper struct {
	fn rpcHnadlerFnType
}

func (r rpcHandlerFnWrapper) Handle(req []byte) (proto.Message, error) {
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

func (u *UnixSocketRpcServer) Listen(ctx context.Context) error {
	managementSocket, err := net.Listen("unix", u.socketPath)
	if err != nil {
		return err
	}

	go func() {
		<-ctx.Done()
		os.Remove(u.socketPath)
	}()

	for {
		conn, err := managementSocket.Accept()
		if err != nil {
			return err
		}

		go func(conn net.Conn) {
			defer conn.Close()
			for {
				requestLengthBytes := make([]byte, 8)
				if _, err := conn.Read(requestLengthBytes); err != nil {
					if errors.Is(err, io.EOF) {
						return
					}
					panic(err)
				}
				requestLength := binary.BigEndian.Uint64(requestLengthBytes)
				fmt.Printf("Request length is: %d\n", requestLength)
				requestBytes := make([]byte, requestLength)
				isEof := false
				if _, err = conn.Read(requestBytes); err != nil {
					if errors.Is(err, io.EOF) {
						isEof = true
					} else {
						panic(err) // todo: propagate error instead
					}
				}

				request := rpcprotocol.Request{}
				proto.Unmarshal(requestBytes, &request)

				var responsePayload proto.Message
				if handler, ok := u.handlers[request.Method]; ok {
					responsePayload, err = handler.Handle(request.Payload)
				} else if u.fallback != nil {
					responsePayload, err = u.fallback.Handle(request.Payload)
				}
				if err != nil {
					panic(err) // todo: do something about it
				}

				responsePayloadSerialised, err := proto.Marshal(responsePayload)
				if err != nil {
					panic(err) // todo: do something about it
				}

				response := rpcprotocol.Response{
					Payload: responsePayloadSerialised,
				}
				resBytes, err := proto.Marshal(&response)
				if err != nil {
					panic(err)
				}

				responseLength := make([]byte, 8)
				binary.BigEndian.PutUint64(responseLength, uint64(len(resBytes)))
				conn.Write(responseLength)
				conn.Write(resBytes)

				if isEof {
					return
				}
			}
		}(conn)
	}
}

type UnixSocketRpcClient struct {
	socketPath string
	connection net.Conn
	m          sync.Mutex
}

func NewUnixSocketRpcClient(socket string) *UnixSocketRpcClient {
	return &UnixSocketRpcClient{
		socketPath: socket,
	}
}

func (u *UnixSocketRpcClient) Send(method string, msg proto.Message) ([]byte, error) {
	u.m.Lock()
	defer u.m.Unlock()
	if u.connection == nil {
		conn, err := net.Dial("unix", u.socketPath)
		if err != nil {
			return nil, err
		}
		u.connection = conn
	}

	msgSerialised, err := proto.Marshal(msg)
	if err != nil {
		return nil, err
	}

	request := rpcprotocol.Request{
		Method:  method,
		Payload: msgSerialised,
	}

	requestBytes, err := proto.Marshal(&request)
	if err != nil {
		return nil, err
	}

	requestLength := make([]byte, 8)
	binary.BigEndian.PutUint64(requestLength, uint64(len(requestBytes)))
	u.connection.Write(requestLength)
	u.connection.Write(requestBytes)

	responseLengthBytes := make([]byte, 8)
	if _, err := u.connection.Read(responseLengthBytes); err != nil {
		panic(err)
	}
	responseLength := binary.BigEndian.Uint64(responseLengthBytes)
	responseBytes := make([]byte, responseLength)

	if _, err = u.connection.Read(responseBytes); err != nil {
		if errors.Is(err, io.EOF) {
			if err = u.connection.Close(); err != nil {
				return nil, err
			}
		} else {
			return nil, err
		}
	}

	response := rpcprotocol.Response{}
	if err = proto.Unmarshal(responseBytes, &response); err != nil {
		return nil, err
	}

	return response.Payload, nil
}
