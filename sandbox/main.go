package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/TheGrizzlyDev/macbox/sandbox/manage"
)

var (
	socketPath = flag.String("socket", "", "")
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		panic(err)
	}
}

func run(args []string) error {
	if err := flag.CommandLine.Parse(args); err != nil {
		flag.Usage()
		return nil
	}

	ctx, cancel := context.WithCancel(context.Background())

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM, os.Interrupt, os.Kill)
	go func() {
		<-c
		cancel()
		os.Exit(1)
	}()

	server, err := manage.NewManagerServer(func(id string) (manage.Server, error) {
		apiSocketPath := fmt.Sprintf("/tmp/macbox.%s.sock", id)
		sandboxServer, err := manage.NewUnixSocketServer(apiSocketPath)
		if err != nil {
			return nil, err
		}
		go func() {
			fmt.Printf("Listening on '%s' for sandbox '%s'\n", apiSocketPath, id)
			sandboxServer.Listen(ctx)
		}()
		return sandboxServer, nil
	})

	if err != nil {
		return err
	}

	server.ListenToUnixSocket(ctx, *socketPath)

	return nil
}
