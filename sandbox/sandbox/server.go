package sandbox

import (
	"context"

	"github.com/TheGrizzlyDev/macbox/common/rpc"
	rpccore "github.com/TheGrizzlyDev/macbox/proto/macbox/core/v1"
	"google.golang.org/protobuf/proto"
)

type ApiServer struct {
	socket string
}

func NewApiServer(socket string) *ApiServer {
	return &ApiServer{socket: socket}
}

func wrapResponse(m proto.Message) (proto.Message, error) {
	payload, err := proto.Marshal(m)
	if err != nil {
		return nil, err
	}
	return &rpccore.ApiResponse{Payload: payload}, nil
}

func (a *ApiServer) Listen(ctx context.Context) error {
	server := rpc.NewUnixSocketRpcServer(a.socket)
	server.AddHandler("cwd", rpc.RpcHandlerFn(func(requestBytes []byte) (proto.Message, error) {
		return wrapResponse(&rpccore.CwdResponse{Path: "/bla/bla"})
	}))
	return server.Listen(ctx)
}
