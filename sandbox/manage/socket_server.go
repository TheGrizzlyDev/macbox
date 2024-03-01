package manage

import (
	"context"
	"fmt"

	"github.com/TheGrizzlyDev/macbox/sandbox/sandbox"
)

type UnixSocketServer struct {
	socket string
}

func NewUnixSocketServer(socket string) (*UnixSocketServer, error) {
	server := UnixSocketServer{socket: socket}

	return &server, nil
}

func (u *UnixSocketServer) Listen(ctx context.Context) error {
	server := sandbox.NewApiServer(u.socket)
	return server.Listen(ctx)
}

func (u *UnixSocketServer) Exec(ctx context.Context, args []string) (*ExecResponse, error) {
	fmt.Println("exec", args)
	return nil, nil
}

func (u *UnixSocketServer) Stop(context.Context) {
	fmt.Println("stop")
}
