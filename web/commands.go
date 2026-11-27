package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os/exec"
	"syscall"
	"time"
)

func run(ctx context.Context, env []string, program string, args ...string) (stdout, stderr string, err error) {
	cmd := exec.CommandContext(ctx, program, args...)
	cmd.Env = env
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	cmd.Cancel = func() error { return syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL) }
	cmd.WaitDelay = 5 * time.Second
	var out, diagnostic bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &diagnostic
	err = cmd.Run()
	return out.String(), diagnostic.String(), err
}

func fingerprint(value any) string {
	data, err := json.Marshal(value)
	if err != nil {
		panic(err)
	}
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}
