package manage

import (
	"context"
	"fmt"
	"sync"

	"github.com/google/uuid"

	"github.com/TheGrizzlyDev/macbox/common/rpc"
	rpcmanage "github.com/TheGrizzlyDev/macbox/proto/macbox/manage/v1"
	"google.golang.org/protobuf/proto"
)

type sandboxCreator = func(string) (Server, error)

type Manager struct {
	create_fn sandboxCreator
	sandboxes map[string]Server
	mu        sync.RWMutex
}

func NewManager(create_sandbox_fn sandboxCreator) (*Manager, error) {
	return &Manager{create_fn: create_sandbox_fn, sandboxes: make(map[string]Server)}, nil
}

func (m *Manager) CreateSandbox() (string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	id := uuid.New().String()
	if sandbox, err := m.create_fn(id); err != nil {
		return "", err
	} else {
		m.sandboxes[id] = sandbox
	}
	return id, nil
}

func (m *Manager) GetSandbox(sandbox_uuid string) (Server, bool) {
	m.mu.RLock()
	defer m.mu.RLock()
	sandbox, ok := m.sandboxes[sandbox_uuid]
	return sandbox, ok
}

type ManagerServer struct {
	m *Manager
}

func NewManagerServer(create_sandbox_fn sandboxCreator) (*ManagerServer, error) {
	manager, err := NewManager(create_sandbox_fn)
	if err != nil {
		return nil, err
	}
	return &ManagerServer{m: manager}, nil
}

func (m *ManagerServer) ListenToUnixSocket(ctx context.Context, socket string) error {
	managementServer := rpc.NewUnixSocketRpcServer(socket)
	managementServer.AddHandler("create", rpc.RpcHandlerFn(func(request proto.Message) (proto.Message, error) {
		if id, err := m.m.CreateSandbox(); err != nil {
			return nil, err
		} else {
			return &rpcmanage.CreateSandboxResponse{
				SandboxUuid: id,
			}, nil
		}
	}))
	managementServer.AddHandler("exec", rpc.RpcHandlerFn(func(request proto.Message) (proto.Message, error) {
		fmt.Println(request)
		return nil, nil
	}))

	return managementServer.Listen(ctx)
}
