package manage

import (
	"context"
	"fmt"
)

type UnixSocketServer struct {
	socket string
}

func NewUnixSocketServer(socket string) (*UnixSocketServer, error) {
	server := UnixSocketServer{socket: socket}

	return &server, nil
}

func (u *UnixSocketServer) Listen(ctx context.Context) error {
	fmt.Println("listening...")
	return nil
}

func (u *UnixSocketServer) Exec(ctx context.Context, args []string) (*ExecResponse, error) {
	fmt.Println("exec", args)
	return nil, nil
}

func (u *UnixSocketServer) Stop(context.Context) {
	fmt.Println("stop")
}
