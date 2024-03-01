package sandbox

import (
	"context"
	"fmt"

	"github.com/TheGrizzlyDev/macbox/common/rpc"
	rpccore "github.com/TheGrizzlyDev/macbox/proto/macbox/core/v1"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"
)

type ApiServer struct {
	socket string
}

func NewApiServer(socket string) *ApiServer {
	return &ApiServer{socket: socket}
}

func (a *ApiServer) Listen(ctx context.Context) error {
	server := rpc.NewUnixSocketRpcServer(a.socket)
	server.AddHandler("cwd", rpc.RpcHandlerFn(func(requestAsAny *anypb.Any) (proto.Message, error) {
		fmt.Println(requestAsAny)
		return &rpccore.CwdResponse{Path: "/bla/bla"}, nil
	}))
	return server.Listen(ctx)
}
